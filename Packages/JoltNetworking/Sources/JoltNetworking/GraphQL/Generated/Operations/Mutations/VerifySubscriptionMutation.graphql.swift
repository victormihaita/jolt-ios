// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension JoltAPI {
  class VerifySubscriptionMutation: GraphQLMutation {
    public static let operationName: String = "VerifySubscription"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation VerifySubscription { verifySubscription { __typename id email displayName avatarUrl timezone isPremium premiumUntil } }"#
      ))

    public init() {}

    public struct Data: JoltAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.Mutation }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("verifySubscription", VerifySubscription.self),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        VerifySubscriptionMutation.Data.self
      ] }

      public var verifySubscription: VerifySubscription { __data["verifySubscription"] }

      /// VerifySubscription
      ///
      /// Parent Type: `User`
      public struct VerifySubscription: JoltAPI.SelectionSet {
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
        ] }
        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          VerifySubscriptionMutation.Data.VerifySubscription.self
        ] }

        public var id: JoltAPI.UUID { __data["id"] }
        public var email: String { __data["email"] }
        public var displayName: String { __data["displayName"] }
        public var avatarUrl: String? { __data["avatarUrl"] }
        public var timezone: String { __data["timezone"] }
        public var isPremium: Bool { __data["isPremium"] }
        public var premiumUntil: JoltAPI.DateTime? { __data["premiumUntil"] }
      }
    }
  }

}