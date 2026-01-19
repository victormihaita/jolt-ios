import Foundation
import Apollo
import ApolloWebSocket
import ApolloSQLite
import JoltCore
import JoltKeychain

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

/// GraphQL client for communicating with the Jolt API
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

        // HTTP transport for queries and mutations
        let httpTransport = RequestChainNetworkTransport(
            interceptorProvider: NetworkInterceptorProvider(
                client: URLSessionClient(),
                store: store
            ),
            endpointURL: URL(string: JoltConstants.API.graphQLURL)!
        )

        // WebSocket transport for subscriptions
        let webSocket = WebSocket(
            url: URL(string: JoltConstants.API.webSocketURL)!,
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
            let fileURL = documentsURL.appendingPathComponent("jolt-apollo.sqlite")
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
            NetworkFetchInterceptor(client: client),
            ResponseCodeInterceptor(),
            JSONResponseParsingInterceptor(),
            TokenRefreshInterceptor(),  // Handles token refresh on auth errors
            CacheWriteInterceptor(store: store),
        ]
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
            print("🔐 AuthInterceptor: Adding token (length=\(token.count)) for \(Operation.operationName)")
            request.addHeader(name: "Authorization", value: "Bearer \(token)")
        } else {
            print("🔐 AuthInterceptor: No token found for \(Operation.operationName)")
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

    func interceptAsync<Operation: GraphQLOperation>(
        chain: any RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void
    ) {
        print("🔄 TokenRefreshInterceptor: interceptAsync called for \(Operation.operationName)")

        // Debug: Log the response details
        if let httpResponse = response?.httpResponse {
            print("🔄 TokenRefreshInterceptor: HTTP status: \(httpResponse.statusCode)")
        }

        if let parsedResponse = response?.parsedResponse {
            print("🔄 TokenRefreshInterceptor: Checking parsed response for \(Operation.operationName)")
            if let data = parsedResponse.data {
                print("🔄 TokenRefreshInterceptor: Has data: \(data)")
            } else {
                print("🔄 TokenRefreshInterceptor: No data in response")
            }
            if let errors = parsedResponse.errors {
                print("🔄 TokenRefreshInterceptor: Found \(errors.count) errors")
                for error in errors {
                    print("🔄 TokenRefreshInterceptor: Error message: \(error.message ?? "nil")")
                    print("🔄 TokenRefreshInterceptor: Error extensions: \(String(describing: error.extensions))")
                    let isAuthError = isAuthorizationError(error)
                    print("🔄 TokenRefreshInterceptor: Is auth error: \(isAuthError)")
                }
            } else {
                print("🔄 TokenRefreshInterceptor: No errors in parsed response")
            }
        } else {
            print("🔄 TokenRefreshInterceptor: No parsed response yet")
        }

        // Check if the response contains an authorization error
        guard let errors = response?.parsedResponse?.errors,
              errors.contains(where: { isAuthorizationError($0) }) else {
            // No auth error, proceed normally
            print("🔄 TokenRefreshInterceptor: No auth error detected, proceeding")
            chain.proceedAsync(request: request, response: response, interceptor: self, completion: completion)
            return
        }

        print("🔄 TokenRefreshInterceptor: Authorization error detected, attempting refresh")

        // Check if this is a refresh token mutation itself - don't refresh if refresh fails
        if Operation.operationName == "RefreshToken" {
            print("🔄 TokenRefreshInterceptor: Refresh token mutation failed, not retrying")
            chain.proceedAsync(request: request, response: response, interceptor: self, completion: completion)
            return
        }

        // Attempt to refresh the token
        refreshToken { [weak self] success in
            guard let self = self else { return }

            if success {
                print("🔄 TokenRefreshInterceptor: Token refreshed, retrying request")
                // Update the authorization header with new token
                if let newToken = KeychainService.shared.getToken() {
                    request.addHeader(name: "Authorization", value: "Bearer \(newToken)")
                }
                // Retry the request
                chain.retry(request: request, completion: completion)
            } else {
                print("🔄 TokenRefreshInterceptor: Token refresh failed")
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

        // If already refreshing, wait for the result
        if Self.isRefreshing {
            Self.lock.unlock()
            // Queue this completion to be called when refresh completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Check if token was refreshed
                completion(KeychainService.shared.getToken() != nil)
            }
            return
        }

        Self.isRefreshing = true
        Self.lock.unlock()

        guard let refreshToken = KeychainService.shared.getRefreshToken() else {
            print("🔄 TokenRefreshInterceptor: No refresh token available")
            Self.lock.lock()
            Self.isRefreshing = false
            Self.lock.unlock()
            completion(false)
            return
        }

        // Call the refresh token mutation directly using URLSession
        // to avoid circular dependency with the interceptor chain
        performRefreshTokenRequest(refreshToken: refreshToken) { result in
            Self.lock.lock()
            Self.isRefreshing = false
            Self.lock.unlock()

            switch result {
            case .success(let tokens):
                // Save new tokens
                KeychainService.shared.saveToken(tokens.accessToken)
                KeychainService.shared.saveRefreshToken(tokens.refreshToken)
                print("🔄 TokenRefreshInterceptor: New tokens saved")
                completion(true)
            case .failure(let error):
                print("🔄 TokenRefreshInterceptor: Refresh failed: \(error)")
                completion(false)
            }
        }
    }

    private struct RefreshTokens {
        let accessToken: String
        let refreshToken: String
    }

    private func performRefreshTokenRequest(refreshToken: String, completion: @escaping (Result<RefreshTokens, Error>) -> Void) {
        let url = URL(string: JoltConstants.API.graphQLURL)!
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
                    print("🔄 RefreshToken request error: \(error)")
                    completion(.failure(error))
                    return
                }

                guard let data = data else {
                    print("🔄 RefreshToken: no data in response")
                    completion(.failure(NetworkError.invalidResponse))
                    return
                }

                // Debug: print raw response
                if let responseStr = String(data: data, encoding: .utf8) {
                    print("🔄 RefreshToken raw response: \(responseStr)")
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let dataDict = json["data"] as? [String: Any],
                       let refreshTokenDict = dataDict["refreshToken"] as? [String: Any],
                       let accessToken = refreshTokenDict["accessToken"] as? String,
                       let newRefreshToken = refreshTokenDict["refreshToken"] as? String {
                        print("🔄 RefreshToken success: got new tokens")
                        completion(.success(RefreshTokens(accessToken: accessToken, refreshToken: newRefreshToken)))
                    } else {
                        // Check for errors
                        if let errorsArray = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["errors"] as? [[String: Any]],
                           let firstError = errorsArray.first,
                           let message = firstError["message"] as? String {
                            print("🔄 RefreshToken GraphQL error: \(message)")
                            completion(.failure(NetworkError.graphQLErrors([message])))
                        } else {
                            print("🔄 RefreshToken: invalid response structure")
                            completion(.failure(NetworkError.invalidResponse))
                        }
                    }
                } catch {
                    print("🔄 RefreshToken parse error: \(error)")
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}
