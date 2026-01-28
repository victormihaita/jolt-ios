// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension PRAPI {
  class AuthenticateWithAppleMutation: GraphQLMutation {
    public static let operationName: String = "AuthenticateWithApple"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation AuthenticateWithApple($input: AuthenticateWithAppleInput!) { authenticateWithApple(input: $input) { __typename accessToken refreshToken expiresIn user { __typename id email displayName avatarUrl timezone isPremium premiumUntil } } }"#
      ))

    public var input: AuthenticateWithAppleInput

    public init(input: AuthenticateWithAppleInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    public struct Data: PRAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { PRAPI.Objects.Mutation }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("authenticateWithApple", AuthenticateWithApple.self, arguments: ["input": .variable("input")]),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        AuthenticateWithAppleMutation.Data.self
      ] }

      public var authenticateWithApple: AuthenticateWithApple { __data["authenticateWithApple"] }

      /// AuthenticateWithApple
      ///
      /// Parent Type: `AuthPayload`
      public struct AuthenticateWithApple: PRAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { PRAPI.Objects.AuthPayload }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("accessToken", String.self),
          .field("refreshToken", String.self),
          .field("expiresIn", Int.self),
          .field("user", User.self),
        ] }
        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          AuthenticateWithAppleMutation.Data.AuthenticateWithApple.self
        ] }

        public var accessToken: String { __data["accessToken"] }
        public var refreshToken: String { __data["refreshToken"] }
        public var expiresIn: Int { __data["expiresIn"] }
        public var user: User { __data["user"] }

        /// AuthenticateWithApple.User
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
          ] }
          public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            AuthenticateWithAppleMutation.Data.AuthenticateWithApple.User.self
          ] }

          public var id: PRAPI.UUID { __data["id"] }
          public var email: String { __data["email"] }
          public var displayName: String { __data["displayName"] }
          public var avatarUrl: String? { __data["avatarUrl"] }
          public var timezone: String { __data["timezone"] }
          public var isPremium: Bool { __data["isPremium"] }
          public var premiumUntil: PRAPI.DateTime? { __data["premiumUntil"] }
        }
      }
    }
  }

}