// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension JoltAPI {
  struct ReminderListFragment: JoltAPI.SelectionSet, Fragment {
    public static var fragmentDefinition: StaticString {
      #"fragment ReminderListFragment on ReminderList { __typename id name colorHex iconName sortOrder isDefault reminderCount createdAt updatedAt }"#
    }

    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.ReminderList }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("__typename", String.self),
      .field("id", JoltAPI.UUID.self),
      .field("name", String.self),
      .field("colorHex", String.self),
      .field("iconName", String.self),
      .field("sortOrder", Int.self),
      .field("isDefault", Bool.self),
      .field("reminderCount", Int.self),
      .field("createdAt", JoltAPI.DateTime.self),
      .field("updatedAt", JoltAPI.DateTime.self),
    ] }
    public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      ReminderListFragment.self
    ] }

    public var id: JoltAPI.UUID { __data["id"] }
    public var name: String { __data["name"] }
    public var colorHex: String { __data["colorHex"] }
    public var iconName: String { __data["iconName"] }
    public var sortOrder: Int { __data["sortOrder"] }
    public var isDefault: Bool { __data["isDefault"] }
    public var reminderCount: Int { __data["reminderCount"] }
    public var createdAt: JoltAPI.DateTime { __data["createdAt"] }
    public var updatedAt: JoltAPI.DateTime { __data["updatedAt"] }
  }

}