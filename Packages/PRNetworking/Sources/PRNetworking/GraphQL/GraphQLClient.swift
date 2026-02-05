import Foundation
import Apollo
import ApolloWebSocket
import ApolloSQLite
import PRCore
import PRKeychain

// MARK: - Watcher Protocol

/// A cancellable watcher that can be refetched
public protocol GraphQLWatcher: AnyObject {
    func cancel()
    func refetch()
}

/// Type-erased wrapper for Apollo's GraphQLQueryWatcher
public final class AnyGraphQLWatcher<Query: GraphQLQuery>: GraphQLWatcher {
    private let watcher: GraphQLQueryWatcher<Query>

    init(_ watcher: GraphQLQueryWatcher<Query>) {
        self.watcher = watcher
    }

    public func cancel() {
        watcher.cancel()
    }

    public func refetch() {
        watcher.refetch()
    }
}

// MARK: - GraphQL Client

/// GraphQL client for communicating with the PR API
/// Uses SQLite normalized cache for persistence and query watchers for reactive updates
public final class GraphQLClient {
    public static let shared = GraphQLClient()

    /// Notification posted when mutations occur that require refetching
    public static let refetchNotification = Notification.Name("GraphQLClient.Refetch")

    private var apollo: ApolloClient!
    private var store: ApolloStore!
    private var webSocketTransport: WebSocketTransport?

    private init() {
        setupApolloClient()
    }

    private func setupApolloClient() {
        // Create SQLite persistent cache
        store = Self.createApolloStore()

        // Create URLSession with no caching to avoid stale responses
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        sessionConfig.urlCache = nil
        let urlSessionClient = URLSessionClient(sessionConfiguration: sessionConfig)

        print("🌐 GraphQL endpoint: \(PRConstants.API.graphQLURL)")

        // HTTP transport for queries and mutations
        let httpTransport = RequestChainNetworkTransport(
            interceptorProvider: NetworkInterceptorProvider(
                client: urlSessionClient,
                store: store
            ),
            endpointURL: URL(string: PRConstants.API.graphQLURL)!
        )

        // WebSocket transport for subscriptions
        let webSocket = WebSocket(
            url: URL(string: PRConstants.API.webSocketURL)!,
            protocol: .graphql_transport_ws
        )

        let webSocketTransport = WebSocketTransport(
            websocket: webSocket,
            config: WebSocketTransport.Configuration(
                reconnectionInterval: 1.0,
                connectOnInit: false
            )
        )

        // Set connection params with auth token
        if let token = KeychainService.shared.getToken() {
            webSocketTransport.updateConnectingPayload([
                "Authorization": "Bearer \(token)"
            ])
        }

        self.webSocketTransport = webSocketTransport

        // Split transport: WebSocket for subscriptions, HTTP for everything else
        let splitTransport = SplitNetworkTransport(
            uploadingNetworkTransport: httpTransport,
            webSocketNetworkTransport: webSocketTransport
        )

        apollo = ApolloClient(networkTransport: splitTransport, store: store)
    }

    // MARK: - Cache Setup

    private static func createApolloStore() -> ApolloStore {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return ApolloStore(cache: InMemoryNormalizedCache())
        }

        do {
            let fileURL = documentsURL.appendingPathComponent("pr-apollo.sqlite")
            let cache = try SQLiteNormalizedCache(fileURL: fileURL)
            return ApolloStore(cache: cache)
        } catch {
            print("Failed to create SQLite cache, falling back to in-memory: \(error)")
            return ApolloStore(cache: InMemoryNormalizedCache())
        }
    }

    // MARK: - Connection Management

    public func connect() {
        webSocketTransport?.resumeWebSocketConnection()
    }

    public func disconnect() {
        webSocketTransport?.closeConnection()
    }

    public func updateAuthToken(_ token: String?) {
        if let token = token {
            webSocketTransport?.updateConnectingPayload([
                "Authorization": "Bearer \(token)"
            ])
        } else {
            webSocketTransport?.updateConnectingPayload([:])
        }
    }

    // MARK: - Watch (Reactive Queries)

    /// Watches a query for changes. Returns cached data immediately, then fetches from network.
    /// The handler is called whenever the cache is updated (from network fetch or mutations).
    ///
    /// - Parameters:
    ///   - query: The GraphQL query to watch
    ///   - handler: Called with the result whenever data changes
    /// - Returns: A watcher that can be cancelled or manually refetched
    public func watch<Query: GraphQLQuery>(
        query: Query,
        handler: @escaping (Result<Query.Data, Error>) -> Void
    ) -> GraphQLWatcher {
        let watcher = apollo.watch(
            query: query,
            cachePolicy: .returnCacheDataAndFetch
        ) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors, !errors.isEmpty {
                    let errorMessages = errors.map { $0.localizedDescription }
                    handler(.failure(NetworkError.graphQLErrors(errorMessages)))
                    return
                }
                guard let data = graphQLResult.data else {
                    // No data yet (cache miss, network pending)
                    return
                }
                handler(.success(data))
            case .failure(let error):
                handler(.failure(NetworkError.networkError(error)))
            }
        }

        return AnyGraphQLWatcher(watcher)
    }

    // MARK: - Fetch (One-time Query)

    /// Fetches a query once with network request.
    /// - Parameters:
    ///   - query: The GraphQL query to fetch
    ///   - storeInCache: If true, stores result in cache. If false, ignores cache completely.
    /// - Returns: The query data
    ///
    /// For reactive cache-first behavior, use `watch` instead.
    public func fetch<Query: GraphQLQuery>(
        query: Query,
        storeInCache: Bool = true
    ) async throws -> Query.Data {
        try await withCheckedThrowingContinuation { continuation in
            // Use fetchIgnoringCacheData to always hit network but still write to cache
            // Use fetchIgnoringCacheCompletely to skip cache entirely
            let policy: CachePolicy = storeInCache ? .fetchIgnoringCacheData : .fetchIgnoringCacheCompletely

            apollo.fetch(query: query, cachePolicy: policy) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        let errorMessages = errors.map { $0.localizedDescription }
                        continuation.resume(throwing: NetworkError.graphQLErrors(errorMessages))
                        return
                    }
                    guard let data = graphQLResult.data else {
                        continuation.resume(throwing: NetworkError.invalidResponse)
                        return
                    }
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: NetworkError.networkError(error))
                }
            }
        }
    }

    // MARK: - Mutation Execution

    /// Performs a mutation and updates the normalized cache.
    /// Posts a refetch notification for mutations that modify data.
    public func perform<Mutation: GraphQLMutation>(
        mutation: Mutation,
        publishResultToStore: Bool = true
    ) async throws -> Mutation.Data {
        let result: Mutation.Data = try await withCheckedThrowingContinuation { continuation in
            apollo.perform(
                mutation: mutation,
                publishResultToStore: publishResultToStore
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors, !errors.isEmpty {
                        // Check for specific error codes
                        for error in errors {
                            if let extensions = error.extensions,
                               let code = extensions["code"] as? String {
                                switch code {
                                case "UNAUTHORIZED":
                                    continuation.resume(throwing: NetworkError.unauthorized)
                                    return
                                case "PREMIUM_REQUIRED":
                                    continuation.resume(throwing: NetworkError.premiumRequired)
                                    return
                                default:
                                    break
                                }
                            }
                        }

                        let errorMessages = errors.map { $0.localizedDescription }
                        continuation.resume(throwing: NetworkError.graphQLErrors(errorMessages))
                        return
                    }
                    guard let data = graphQLResult.data else {
                        continuation.resume(throwing: NetworkError.invalidResponse)
                        return
                    }
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: NetworkError.networkError(error))
                }
            }
        }

        // Post refetch notification for data-modifying mutations
        if Self.shouldTriggerRefetch(for: Mutation.operationName) {
            print("📣 GraphQLClient: Posting refetch notification for \(Mutation.operationName)")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Self.refetchNotification, object: nil)
            }
        }

        return result
    }

    // MARK: - Subscription

    public func subscribe<Subscription: GraphQLSubscription>(
        subscription: Subscription,
        handler: @escaping (Result<Subscription.Data, Error>) -> Void
    ) -> Cancellable {
        apollo.subscribe(subscription: subscription) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors, !errors.isEmpty {
                    let errorMessages = errors.map { $0.localizedDescription }
                    handler(.failure(NetworkError.graphQLErrors(errorMessages)))
                    return
                }
                guard let data = graphQLResult.data else {
                    handler(.failure(NetworkError.invalidResponse))
                    return
                }
                handler(.success(data))
            case .failure(let error):
                handler(.failure(NetworkError.networkError(error)))
            }
        }
    }

    // MARK: - Cache Management

    /// Clears all cached data
    public func clearCache() {
        apollo.clearCache { result in
            if case .failure(let error) = result {
                print("Failed to clear cache: \(error)")
            }
        }
    }

    /// Evicts a specific object from the cache by its ID
    public func evictCachedObject(for id: String) {
        store.withinReadWriteTransaction { transaction in
            try transaction.removeObject(for: id)
        } completion: { result in
            if case .failure(let error) = result {
                print("Failed to evict cache object: \(error)")
            }
        }
    }

    // MARK: - Offline-Aware Mutation

    /// Performs a mutation with offline support.
    /// If offline, the mutation is queued for later sync.
    /// - Parameters:
    ///   - mutation: The GraphQL mutation to perform
    ///   - queuedMutation: Optional pre-built queued mutation for offline storage
    ///   - optimisticUpdate: Optional closure to update local state optimistically
    /// - Returns: The mutation data if online, throws NetworkError.offline if queued
    public func performWithOfflineSupport<Mutation: GraphQLMutation>(
        mutation: Mutation,
        queuedMutation: QueuedMutation?,
        optimisticUpdate: (() -> Void)? = nil
    ) async throws -> Mutation.Data {
        // Check network connectivity
        guard NetworkReachability.shared.isConnected else {
            // Apply optimistic update
            optimisticUpdate?()

            // Queue for later sync
            if let queued = queuedMutation {
                OfflineMutationQueue.shared.enqueue(queued)
            }

            throw NetworkError.offline
        }

        // Attempt mutation online
        do {
            return try await perform(mutation: mutation)
        } catch let error as NetworkError {
            // On network error, queue the mutation
            if error.isOffline {
                optimisticUpdate?()
                if let queued = queuedMutation {
                    OfflineMutationQueue.shared.enqueue(queued)
                }
                throw NetworkError.offline
            }
            throw error
        }
    }

    // MARK: - Replay Queued Mutations

    /// Replays a queued mutation. Called by SyncEngine when processing the offline queue.
    public func replayMutation(_ mutation: QueuedMutation) async -> QueueProcessingResult {
        do {
            switch mutation.operationType {
            case .create:
                return try await replayCreateReminder(mutation)
            case .update:
                return try await replayUpdateReminder(mutation)
            case .delete:
                return try await replayDeleteReminder(mutation)
            case .complete:
                return try await replayCompleteReminder(mutation)
            case .snooze:
                return try await replaySnoozeReminder(mutation)
            case .dismiss:
                return try await replayDismissReminder(mutation)
            }
        } catch let error as NetworkError {
            if error.isRetryable {
                return .retryableFailure(error: error)
            }
            return .permanentFailure(error: error)
        } catch {
            return .permanentFailure(error: error)
        }
    }

    private func replayCreateReminder(_ mutation: QueuedMutation) async throws -> QueueProcessingResult {
        let payload = try JSONDecoder().decode(CreateReminderPayload.self, from: mutation.payload)

        var recurrenceRuleInput: GraphQLNullable<PRAPI.RecurrenceRuleInput> = .null
        if let rule = payload.recurrenceRule,
           let frequency = PRAPI.Frequency(rawValue: rule.frequency) {
            recurrenceRuleInput = .some(PRAPI.RecurrenceRuleInput(
                frequency: .init(frequency),
                interval: rule.interval,
                daysOfWeek: rule.daysOfWeek.map { .some($0) } ?? .null,
                dayOfMonth: rule.dayOfMonth.map { .some($0) } ?? .null,
                monthOfYear: rule.monthOfYear.map { .some($0) } ?? .null,
                endAfterOccurrences: rule.endAfterOccurrences.map { .some($0) } ?? .null,
                endDate: rule.endDate.map { .some($0) } ?? .null
            ))
        }

        let input = PRAPI.CreateReminderInput(
            listId: payload.listId.map { .some($0) } ?? .null,
            title: payload.title,
            notes: payload.notes.map { .some($0) } ?? .null,
            priority: .some(.init(PRAPI.Priority(rawValue: payload.priority) ?? .normal)),
            dueAt: payload.dueAt.map { .some($0) } ?? .null,
            allDay: payload.allDay.map { .some($0) } ?? .null,
            recurrenceRule: recurrenceRuleInput,
            recurrenceEnd: payload.recurrenceEnd.map { .some($0) } ?? .null,
            tags: payload.tags.map { .some($0) } ?? .null,
            localId: .some(payload.localId)
        )

        let graphQLMutation = PRAPI.CreateReminderMutation(input: input)
        _ = try await perform(mutation: graphQLMutation)

        return .success
    }

    private func replayUpdateReminder(_ mutation: QueuedMutation) async throws -> QueueProcessingResult {
        let payload = try JSONDecoder().decode(UpdateReminderPayload.self, from: mutation.payload)

        // Check version for conflict detection
        let query = PRAPI.ReminderQuery(id: payload.id)
        if let serverData = try? await fetch(query: query, storeInCache: false),
           let serverReminder = serverData.reminder {
            if serverReminder.version > payload.version {
                return .conflict(
                    serverVersion: serverReminder.version,
                    localVersion: payload.version
                )
            }
        }

        var recurrenceRuleInput: GraphQLNullable<PRAPI.RecurrenceRuleInput> = .null
        if let rule = payload.recurrenceRule,
           let frequency = PRAPI.Frequency(rawValue: rule.frequency) {
            recurrenceRuleInput = .some(PRAPI.RecurrenceRuleInput(
                frequency: .init(frequency),
                interval: rule.interval,
                daysOfWeek: rule.daysOfWeek.map { .some($0) } ?? .null,
                dayOfMonth: rule.dayOfMonth.map { .some($0) } ?? .null,
                monthOfYear: rule.monthOfYear.map { .some($0) } ?? .null,
                endAfterOccurrences: rule.endAfterOccurrences.map { .some($0) } ?? .null,
                endDate: rule.endDate.map { .some($0) } ?? .null
            ))
        }

        let input = PRAPI.UpdateReminderInput(
            listId: payload.listId.map { .some($0) } ?? .null,
            title: payload.title.map { .some($0) } ?? .null,
            notes: payload.notes.map { .some($0) } ?? .null,
            priority: payload.priority.flatMap { PRAPI.Priority(rawValue: $0) }.map { .some(.init($0)) } ?? .null,
            dueAt: payload.dueAt.map { .some($0) } ?? .null,
            allDay: payload.allDay.map { .some($0) } ?? .null,
            recurrenceRule: recurrenceRuleInput,
            recurrenceEnd: payload.recurrenceEnd.map { .some($0) } ?? .null,
            status: payload.status.flatMap { PRAPI.ReminderStatus(rawValue: $0) }.map { .some(.init($0)) } ?? .null,
            tags: payload.tags.map { .some($0) } ?? .null
        )

        let graphQLMutation = PRAPI.UpdateReminderMutation(id: payload.id, input: input)
        _ = try await perform(mutation: graphQLMutation)

        return .success
    }

    private func replayDeleteReminder(_ mutation: QueuedMutation) async throws -> QueueProcessingResult {
        let payload = try JSONDecoder().decode(DeleteReminderPayload.self, from: mutation.payload)
        let graphQLMutation = PRAPI.DeleteReminderMutation(id: payload.id)
        _ = try await perform(mutation: graphQLMutation)
        return .success
    }

    private func replayCompleteReminder(_ mutation: QueuedMutation) async throws -> QueueProcessingResult {
        let payload = try JSONDecoder().decode(CompleteReminderPayload.self, from: mutation.payload)
        let graphQLMutation = PRAPI.CompleteReminderMutation(id: payload.id)
        _ = try await perform(mutation: graphQLMutation)
        return .success
    }

    private func replaySnoozeReminder(_ mutation: QueuedMutation) async throws -> QueueProcessingResult {
        let payload = try JSONDecoder().decode(SnoozeReminderPayload.self, from: mutation.payload)
        let graphQLMutation = PRAPI.SnoozeReminderMutation(id: payload.id, minutes: payload.minutes)
        _ = try await perform(mutation: graphQLMutation)
        return .success
    }

    private func replayDismissReminder(_ mutation: QueuedMutation) async throws -> QueueProcessingResult {
        let payload = try JSONDecoder().decode(DismissReminderPayload.self, from: mutation.payload)
        let graphQLMutation = PRAPI.DismissReminderMutation(id: payload.id)
        _ = try await perform(mutation: graphQLMutation)
        return .success
    }

    // MARK: - Helpers

    private static func shouldTriggerRefetch(for operationName: String) -> Bool {
        let triggerPrefixes = ["Create", "Delete", "Update", "Complete", "Snooze", "Dismiss", "Register", "Unregister"]
        return triggerPrefixes.contains { operationName.hasPrefix($0) }
    }
}

// MARK: - Network Interceptor Provider

private class NetworkInterceptorProvider: InterceptorProvider {
    private let client: URLSessionClient
    private let store: ApolloStore

    init(client: URLSessionClient, store: ApolloStore) {
        self.client = client
        self.store = store
    }

    func interceptors<Operation: GraphQLOperation>(
        for operation: Operation
    ) -> [any ApolloInterceptor] {
        [
            MaxRetryInterceptor(),
            CacheReadInterceptor(store: store),
            AuthInterceptor(),
            RequestLoggingInterceptor(),  // Log request BEFORE network fetch
            NetworkFetchInterceptor(client: client),
            ResponseLoggingInterceptor(),  // Log raw response for debugging
            ResponseCodeInterceptor(),
            JSONResponseParsingInterceptor(),
            TokenRefreshInterceptor(),  // Handles token refresh on auth errors
            CacheWriteInterceptor(store: store),
        ]
    }
}

// MARK: - Request Logging Interceptor

private class RequestLoggingInterceptor: ApolloInterceptor {
    public var id: String = "RequestLoggingInterceptor"

    func interceptAsync<Operation: GraphQLOperation>(
        chain: any RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void
    ) {
        #if DEBUG
        print("📤 OUTGOING REQUEST for \(Operation.operationName):")
        print("📤 URL: \(request.graphQLEndpoint)")
        print("📤 Operation: \(request.operation)")
        print("📤 Headers: \(request.additionalHeaders)")
        #endif

        chain.proceedAsync(
            request: request,
            response: response,
            interceptor: self,
            completion: completion
        )
    }
}

// MARK: - Response Logging Interceptor

private class ResponseLoggingInterceptor: ApolloInterceptor {
    public var id: String = "ResponseLoggingInterceptor"

    func interceptAsync<Operation: GraphQLOperation>(
        chain: any RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void
    ) {
        #if DEBUG
        if let httpResponse = response {
            let rawData = httpResponse.rawData
            let responseString = String(data: rawData, encoding: .utf8) ?? "<binary data>"
            print("📥 RAW RESPONSE for \(Operation.operationName):")
            print(responseString)
        } else {
            print("📥 NO RESPONSE yet for \(Operation.operationName)")
        }
        #endif

        chain.proceedAsync(
            request: request,
            response: response,
            interceptor: self,
            completion: completion
        )
    }
}

// MARK: - Auth Interceptor

private class AuthInterceptor: ApolloInterceptor {
    public var id: String = "AuthInterceptor"

    func interceptAsync<Operation: GraphQLOperation>(
        chain: any RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void
    ) {
        if let token = KeychainService.shared.getToken() {
            #if DEBUG
            print("🔐 AuthInterceptor: Adding token (length=\(token.count)) for \(Operation.operationName)")
            #endif
            request.addHeader(name: "Authorization", value: "Bearer \(token)")
        } else {
            #if DEBUG
            print("🔐 AuthInterceptor: No token found for \(Operation.operationName)")
            #endif
        }

        // Add device ID header so backend can exclude this device from cross-device notifications
        if let deviceID = UserDefaults.standard.string(forKey: "registeredDeviceID") {
            request.addHeader(name: "X-Device-ID", value: deviceID)
            #if DEBUG
            print("🔐 AuthInterceptor: Adding X-Device-ID: \(deviceID)")
            #endif
        }

        chain.proceedAsync(
            request: request,
            response: response,
            interceptor: self,
            completion: completion
        )
    }
}

// MARK: - Token Refresh Interceptor

/// Interceptor that handles automatic token refresh when receiving authorization errors.
/// Must be placed AFTER JSONResponseParsingInterceptor in the chain.
private class TokenRefreshInterceptor: ApolloInterceptor {
    public var id: String = "TokenRefreshInterceptor"

    // Track if a refresh is in progress to prevent concurrent refreshes
    private static var isRefreshing = false
    private static let lock = NSLock()
    private static var pendingCompletions: [(Bool) -> Void] = []

    func interceptAsync<Operation: GraphQLOperation>(
        chain: any RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void
    ) {
        #if DEBUG
        print("🔄 TokenRefreshInterceptor: interceptAsync called for \(Operation.operationName)")

        if let httpResponse = response?.httpResponse {
            print("🔄 TokenRefreshInterceptor: HTTP status: \(httpResponse.statusCode)")
        }

        if let parsedResponse = response?.parsedResponse {
            if let errors = parsedResponse.errors {
                print("🔄 TokenRefreshInterceptor: Found \(errors.count) errors")
                for error in errors {
                    print("🔄 TokenRefreshInterceptor: Error: \(error.message ?? "nil"), isAuth: \(isAuthorizationError(error))")
                }
            }
        }
        #endif

        // Check if the response contains an authorization error
        guard let errors = response?.parsedResponse?.errors,
              errors.contains(where: { isAuthorizationError($0) }) else {
            // No auth error, proceed normally
            chain.proceedAsync(request: request, response: response, interceptor: self, completion: completion)
            return
        }

        #if DEBUG
        print("🔄 TokenRefreshInterceptor: Authorization error detected, attempting refresh")
        #endif

        // Check if this is a refresh token mutation itself - don't refresh if refresh fails
        if Operation.operationName == "RefreshToken" {
            chain.proceedAsync(request: request, response: response, interceptor: self, completion: completion)
            return
        }

        // Attempt to refresh the token
        refreshToken { [weak self] success in
            guard let self = self else { return }

            if success {
                #if DEBUG
                print("🔄 TokenRefreshInterceptor: Token refreshed, retrying request")
                #endif
                // Update the authorization header with new token
                if let newToken = KeychainService.shared.getToken() {
                    request.addHeader(name: "Authorization", value: "Bearer \(newToken)")
                }
                // Retry the request
                chain.retry(request: request, completion: completion)
            } else {
                #if DEBUG
                print("🔄 TokenRefreshInterceptor: Token refresh failed")
                #endif
                // Proceed with the original error response
                chain.proceedAsync(request: request, response: response, interceptor: self, completion: completion)
            }
        }
    }

    private func isAuthorizationError(_ error: GraphQLError) -> Bool {
        // Check for common authorization error patterns
        if let code = error.extensions?["code"] as? String {
            return code == "UNAUTHORIZED" || code == "FORBIDDEN" || code == "UNAUTHENTICATED"
        }
        
        guard let errorMessage = error.message else { return false }
        
        // Also check message for "Unauthorized" text
        return errorMessage.lowercased().contains("unauthorized") ||
                errorMessage.lowercased().contains("token expired")
    }

    private func refreshToken(completion: @escaping (Bool) -> Void) {
        Self.lock.lock()

        // If already refreshing, queue this completion to be notified when done
        if Self.isRefreshing {
            Self.pendingCompletions.append(completion)
            Self.lock.unlock()
            return
        }

        Self.isRefreshing = true
        Self.lock.unlock()

        guard let refreshToken = KeychainService.shared.getRefreshToken() else {
            #if DEBUG
            print("🔄 TokenRefreshInterceptor: No refresh token available")
            #endif
            Self.lock.lock()
            Self.isRefreshing = false
            let pending = Self.pendingCompletions
            Self.pendingCompletions.removeAll()
            Self.lock.unlock()
            completion(false)
            pending.forEach { $0(false) }
            return
        }

        // Call the refresh token mutation directly using URLSession
        // to avoid circular dependency with the interceptor chain
        performRefreshTokenRequest(refreshToken: refreshToken) { result in
            let success: Bool
            switch result {
            case .success(let tokens):
                // Save new tokens
                KeychainService.shared.saveToken(tokens.accessToken)
                KeychainService.shared.saveRefreshToken(tokens.refreshToken)
                #if DEBUG
                print("🔄 TokenRefreshInterceptor: New tokens saved")
                #endif
                success = true
            case .failure(let error):
                #if DEBUG
                print("🔄 TokenRefreshInterceptor: Refresh failed: \(error)")
                #endif
                success = false
            }

            // Notify all waiting callers
            Self.lock.lock()
            Self.isRefreshing = false
            let pending = Self.pendingCompletions
            Self.pendingCompletions.removeAll()
            Self.lock.unlock()

            completion(success)
            pending.forEach { $0(success) }
        }
    }

    private struct RefreshTokens {
        let accessToken: String
        let refreshToken: String
    }

    private func performRefreshTokenRequest(refreshToken: String, completion: @escaping (Result<RefreshTokens, Error>) -> Void) {
        let url = URL(string: PRConstants.API.graphQLURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let query = """
        mutation RefreshToken($refreshToken: String!) {
            refreshToken(refreshToken: $refreshToken) {
                accessToken
                refreshToken
            }
        }
        """

        let body: [String: Any] = [
            "query": query,
            "variables": ["refreshToken": refreshToken]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    #if DEBUG
                    print("🔄 RefreshToken request error: \(error)")
                    #endif
                    completion(.failure(error))
                    return
                }

                // Check HTTP status code
                if let httpResponse = response as? HTTPURLResponse,
                   !(200...299).contains(httpResponse.statusCode) {
                    #if DEBUG
                    print("🔄 RefreshToken: HTTP error \(httpResponse.statusCode)")
                    #endif
                    completion(.failure(NetworkError.invalidResponse))
                    return
                }

                guard let data = data else {
                    #if DEBUG
                    print("🔄 RefreshToken: no data in response")
                    #endif
                    completion(.failure(NetworkError.invalidResponse))
                    return
                }

                #if DEBUG
                if let responseStr = String(data: data, encoding: .utf8) {
                    print("🔄 RefreshToken raw response: \(responseStr)")
                }
                #endif

                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let dataDict = json["data"] as? [String: Any],
                       let refreshTokenDict = dataDict["refreshToken"] as? [String: Any],
                       let accessToken = refreshTokenDict["accessToken"] as? String,
                       let newRefreshToken = refreshTokenDict["refreshToken"] as? String {
                        #if DEBUG
                        print("🔄 RefreshToken success: got new tokens")
                        #endif
                        completion(.success(RefreshTokens(accessToken: accessToken, refreshToken: newRefreshToken)))
                    } else {
                        // Check for errors
                        if let errorsArray = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["errors"] as? [[String: Any]],
                           let firstError = errorsArray.first,
                           let message = firstError["message"] as? String {
                            #if DEBUG
                            print("🔄 RefreshToken GraphQL error: \(message)")
                            #endif
                            completion(.failure(NetworkError.graphQLErrors([message])))
                        } else {
                            #if DEBUG
                            print("🔄 RefreshToken: invalid response structure")
                            #endif
                            completion(.failure(NetworkError.invalidResponse))
                        }
                    }
                } catch {
                    #if DEBUG
                    print("🔄 RefreshToken parse error: \(error)")
                    #endif
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}
