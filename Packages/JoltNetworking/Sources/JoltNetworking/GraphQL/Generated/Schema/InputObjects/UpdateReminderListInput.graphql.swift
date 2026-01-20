// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension JoltAPI {
  struct UpdateReminderListInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
      name: GraphQLNullable<String> = nil,
      colorHex: GraphQLNullable<String> = nil,
      iconName: GraphQLNullable<String> = nil,
      sortOrder: GraphQLNullable<Int> = nil
    ) {
      __data = InputDict([
        "name": name,
        "colorHex": colorHex,
        "iconName": iconName,
        "sortOrder": sortOrder
      ])
    }

    public var name: GraphQLNullable<String> {
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

    public var sortOrder: GraphQLNullable<Int> {
      get { __data["sortOrder"] }
      set { __data["sortOrder"] = newValue }
    }
  }

}