import Foundation

public struct User: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var email: String
    public var displayName: String
    public var avatarUrl: String?
    public var timezone: String
    public var isPremium: Bool
    public var premiumUntil: Date?
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID,
        email: String,
        displayName: String,
        avatarUrl: String? = nil,
        timezone: String = TimeZone.current.identifier,
        isPremium: Bool = false,
        premiumUntil: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.timezone = timezone
        self.isPremium = isPremium
        self.premiumUntil = premiumUntil
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var hasActivePremium: Bool {
        guard isPremium else { return false }
        if let premiumUntil = premiumUntil {
            return premiumUntil > Date()
        }
        return true
    }
}
