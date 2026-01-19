// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension JoltAPI {
  class AuthenticateWithGoogleMutation: GraphQLMutation {
    public static let operationName: String = "AuthenticateWithGoogle"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation AuthenticateWithGoogle($idToken: String!) { authenticateWithGoogle(idToken: $idToken) { __typename accessToken refreshToken expiresIn user { __typename id email displayName avatarUrl timezone isPremium premiumUntil } } }"#
      ))

    public var idToken: String

    public init(idToken: String) {
      self.idToken = idToken
    }

    public var __variables: Variables? { ["idToken": idToken] }

    public struct Data: JoltAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.Mutation }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("authenticateWithGoogle", AuthenticateWithGoogle.self, arguments: ["idToken": .variable("idToken")]),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        AuthenticateWithGoogleMutation.Data.self
      ] }

      public var authenticateWithGoogle: AuthenticateWithGoogle { __data["authenticateWithGoogle"] }

      /// AuthenticateWithGoogle
      ///
      /// Parent Type: `AuthPayload`
      public struct AuthenticateWithGoogle: JoltAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.AuthPayload }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("accessToken", String.self),
          .field("refreshToken", String.self),
          .field("expiresIn", Int.self),
          .field("user", User.self),
        ] }
        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          AuthenticateWithGoogleMutation.Data.AuthenticateWithGoogle.self
        ] }

        public var accessToken: String { __data["accessToken"] }
        public var refreshToken: String { __data["refreshToken"] }
        public var expiresIn: Int { __data["expiresIn"] }
        public var user: User { __data["user"] }

        /// AuthenticateWithGoogle.User
        ///
        /// Parent Type: `User`
        public struct User: JoltAPI.SelectionSet {
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
            AuthenticateWithGoogleMutation.Data.AuthenticateWithGoogle.User.self
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

}