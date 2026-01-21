// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension PRAPI {
  struct CreateReminderListInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
      name: String,
      colorHex: GraphQLNullable<String> = nil,
      iconName: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "name": name,
        "colorHex": colorHex,
        "iconName": iconName
      ])
    }

    public var name: String {
      get { __data["name"] }
      set { __data["name"] = newValue }
    }

    public var colorHex: GraphQLNullable<String> {
      get { __data["colorHex"] }
      set { __data["colorHex"] = newValue }
    }

    public var iconName: GraphQLNullable<String> {
      get { __data["iconName"] }
      set { __data["iconName"] = newValue }
    }
  }

}