// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension JoltAPI {
  class ReorderReminderListsMutation: GraphQLMutation {
    public static let operationName: String = "ReorderReminderLists"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation ReorderReminderLists($ids: [UUID!]!) { reorderReminderLists(ids: $ids) { __typename ...ReminderListFragment } }"#,
        fragments: [ReminderListFragment.self]
      ))

    public var ids: [UUID]

    public init(ids: [UUID]) {
      self.ids = ids
    }

    public var __variables: Variables? { ["ids": ids] }

    public struct Data: JoltAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.Mutation }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("reorderReminderLists", [ReorderReminderList].self, arguments: ["ids": .variable("ids")]),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ReorderReminderListsMutation.Data.self
      ] }

      public var reorderReminderLists: [ReorderReminderList] { __data["reorderReminderLists"] }

      /// ReorderReminderList
      ///
      /// Parent Type: `ReminderList`
      public struct ReorderReminderList: JoltAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.ReminderList }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .fragment(ReminderListFragment.self),
        ] }
        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ReorderReminderListsMutation.Data.ReorderReminderList.self,
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

        public struct Fragments: FragmentContainer {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public var reminderListFragment: ReminderListFragment { _toFragment() }
        }
      }
    }
  }

}