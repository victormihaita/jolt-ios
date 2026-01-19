// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension JoltAPI {
  class RefreshTokenMutation: GraphQLMutation {
    public static let operationName: String = "RefreshToken"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation RefreshToken($refreshToken: String!) { refreshToken(refreshToken: $refreshToken) { __typename accessToken refreshToken expiresIn user { __typename id email displayName avatarUrl timezone isPremium } } }"#
      ))

    public var refreshToken: String

    public init(refreshToken: String) {
      self.refreshToken = refreshToken
    }

    public var __variables: Variables? { ["refreshToken": refreshToken] }

    public struct Data: JoltAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.Mutation }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("refreshToken", RefreshToken.self, arguments: ["refreshToken": .variable("refreshToken")]),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RefreshTokenMutation.Data.self
      ] }

      public var refreshToken: RefreshToken { __data["refreshToken"] }

      /// RefreshToken
      ///
      /// Parent Type: `AuthPayload`
      public struct RefreshToken: JoltAPI.SelectionSet {
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
          RefreshTokenMutation.Data.RefreshToken.self
        ] }

        public var accessToken: String { __data["accessToken"] }
        public var refreshToken: String { __data["refreshToken"] }
        public var expiresIn: Int { __data["expiresIn"] }
        public var user: User { __data["user"] }

        /// RefreshToken.User
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
          ] }
          public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            RefreshTokenMutation.Data.RefreshToken.User.self
          ] }

          public var id: JoltAPI.UUID { __data["id"] }
          public var email: String { __data["email"] }
          public var displayName: String { __data["displayName"] }
          public var avatarUrl: String? { __data["avatarUrl"] }
          public var timezone: String { __data["timezone"] }
          public var isPremium: Bool { __data["isPremium"] }
        }
      }
    }
  }

}