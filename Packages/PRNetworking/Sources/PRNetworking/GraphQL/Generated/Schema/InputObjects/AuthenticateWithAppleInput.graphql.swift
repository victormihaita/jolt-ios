// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension PRAPI {
  struct AuthenticateWithAppleInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
      identityToken: String,
      userIdentifier: String,
      email: GraphQLNullable<String> = nil,
      displayName: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "identityToken": identityToken,
        "userIdentifier": userIdentifier,
        "email": email,
        "displayName": displayName
      ])
    }

    public var identityToken: String {
      get { __data["identityToken"] }
      set { __data["identityToken"] = newValue }
    }

    public var userIdentifier: String {
      get { __data["userIdentifier"] }
      set { __data["userIdentifier"] = newValue }
    }

    public var email: GraphQLNullable<String> {
      get { __data["email"] }
      set { __data["email"] = newValue }
    }

    public var displayName: GraphQLNullable<String> {
      get { __data["displayName"] }
      set { __data["displayName"] = newValue }
    }
  }

}