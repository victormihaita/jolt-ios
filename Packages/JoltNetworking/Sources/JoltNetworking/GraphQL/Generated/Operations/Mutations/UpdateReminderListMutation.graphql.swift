// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension JoltAPI {
  class UpdateReminderListMutation: GraphQLMutation {
    public static let operationName: String = "UpdateReminderList"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation UpdateReminderList($id: UUID!, $input: UpdateReminderListInput!) { updateReminderList(id: $id, input: $input) { __typename ...ReminderListFragment } }"#,
        fragments: [ReminderListFragment.self]
      ))

    public var id: UUID
    public var input: UpdateReminderListInput

    public init(
      id: UUID,
      input: UpdateReminderListInput
    ) {
      self.id = id
      self.input = input
    }

    public var __variables: Variables? { [
      "id": id,
      "input": input
    ] }

    public struct Data: JoltAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.Mutation }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("updateReminderList", UpdateReminderList.self, arguments: [
          "id": .variable("id"),
          "input": .variable("input")
        ]),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UpdateReminderListMutation.Data.self
      ] }

      public var updateReminderList: UpdateReminderList { __data["updateReminderList"] }

      /// UpdateReminderList
      ///
      /// Parent Type: `ReminderList`
      public struct UpdateReminderList: JoltAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.ReminderList }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .fragment(ReminderListFragment.self),
        ] }
        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          UpdateReminderListMutation.Data.UpdateReminderList.self,
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