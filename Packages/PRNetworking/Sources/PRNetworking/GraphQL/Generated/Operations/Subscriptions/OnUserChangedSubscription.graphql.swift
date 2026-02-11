// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension PRAPI {
  class OnUserChangedSubscription: GraphQLSubscription {
    public static let operationName: String = "OnUserChanged"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"subscription OnUserChanged { userChanged { __typename action userId user { __typename id email displayName avatarUrl timezone isPremium premiumUntil createdAt updatedAt } timestamp } }"#
      ))

    public init() {}

    public struct Data: PRAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { PRAPI.Objects.Subscription }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("userChanged", UserChanged.self),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        OnUserChangedSubscription.Data.self
      ] }

      public var userChanged: UserChanged { __data["userChanged"] }

      /// UserChanged
      ///
      /// Parent Type: `UserChangeEvent`
      public struct UserChanged: PRAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { PRAPI.Objects.UserChangeEvent }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("action", GraphQLEnum<PRAPI.ChangeAction>.self),
          .field("userId", PRAPI.UUID.self),
          .field("user", User?.self),
          .field("timestamp", PRAPI.DateTime.self),
        ] }
        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          OnUserChangedSubscription.Data.UserChanged.self
        ] }

        public var action: GraphQLEnum<PRAPI.ChangeAction> { __data["action"] }
        public var userId: PRAPI.UUID { __data["userId"] }
        public var user: User? { __data["user"] }
        public var timestamp: PRAPI.DateTime { __data["timestamp"] }

        /// UserChanged.User
        ///
        /// Parent Type: `User`
        public struct User: PRAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { PRAPI.Objects.User }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", PRAPI.UUID.self),
            .field("email", String.self),
            .field("displayName", String.self),
            .field("avatarUrl", String?.self),
            .field("timezone", String.self),
            .field("isPremium", Bool.self),
            .field("premiumUntil", PRAPI.DateTime?.self),
            .field("createdAt", PRAPI.DateTime.self),
            .field("updatedAt", PRAPI.DateTime.self),
          ] }
          public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            OnUserChangedSubscription.Data.UserChanged.User.self
          ] }

          public var id: PRAPI.UUID { __data["id"] }
          public var email: String { __data["email"] }
          public var displayName: String { __data["displayName"] }
          public var avatarUrl: String? { __data["avatarUrl"] }
          public var timezone: String { __data["timezone"] }
          public var isPremium: Bool { __data["isPremium"] }
          public var premiumUntil: PRAPI.DateTime? { __data["premiumUntil"] }
          public var createdAt: PRAPI.DateTime { __data["createdAt"] }
          public var updatedAt: PRAPI.DateTime { __data["updatedAt"] }
        }
      }
    }
  }

}