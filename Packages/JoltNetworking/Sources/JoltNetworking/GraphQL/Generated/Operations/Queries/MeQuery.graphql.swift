// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension JoltAPI {
  class MeQuery: GraphQLQuery {
    public static let operationName: String = "Me"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Me { me { __typename id email displayName avatarUrl timezone isPremium premiumUntil createdAt } }"#
      ))

    public init() {}

    public struct Data: JoltAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.Query }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("me", Me.self),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MeQuery.Data.self
      ] }

      public var me: Me { __data["me"] }

      /// Me
      ///
      /// Parent Type: `User`
      public struct Me: JoltAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.User }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", JoltAPI.UUID.self),
          .field("email", String.self),
          .field("displayName", String.self),
          .field("avatarUrl", String?.self),
          .field("timezone", String.self),
          .field("isPremium", Bool.self),
          .field("premiumUntil", JoltAPI.DateTime?.self),
          .field("createdAt", JoltAPI.DateTime.self),
        ] }
        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MeQuery.Data.Me.self
        ] }

        public var id: JoltAPI.UUID { __data["id"] }
        public var email: String { __data["email"] }
        public var displayName: String { __data["displayName"] }
        public var avatarUrl: String? { __data["avatarUrl"] }
        public var timezone: String { __data["timezone"] }
        public var isPremium: Bool { __data["isPremium"] }
        public var premiumUntil: JoltAPI.DateTime? { __data["premiumUntil"] }
        public var createdAt: JoltAPI.DateTime { __data["createdAt"] }
      }
    }
  }

}