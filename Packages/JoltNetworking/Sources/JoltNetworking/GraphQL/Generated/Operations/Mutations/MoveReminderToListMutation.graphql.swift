// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension JoltAPI {
  class MoveReminderToListMutation: GraphQLMutation {
    public static let operationName: String = "MoveReminderToList"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation MoveReminderToList($reminderId: UUID!, $listId: UUID!) { moveReminderToList(reminderId: $reminderId, listId: $listId) { __typename ...ReminderFragment } }"#,
        fragments: [ReminderFragment.self]
      ))

    public var reminderId: UUID
    public var listId: UUID

    public init(
      reminderId: UUID,
      listId: UUID
    ) {
      self.reminderId = reminderId
      self.listId = listId
    }

    public var __variables: Variables? { [
      "reminderId": reminderId,
      "listId": listId
    ] }

    public struct Data: JoltAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.Mutation }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("moveReminderToList", MoveReminderToList.self, arguments: [
          "reminderId": .variable("reminderId"),
          "listId": .variable("listId")
        ]),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MoveReminderToListMutation.Data.self
      ] }

      public var moveReminderToList: MoveReminderToList { __data["moveReminderToList"] }

      /// MoveReminderToList
      ///
      /// Parent Type: `Reminder`
      public struct MoveReminderToList: JoltAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.Reminder }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .fragment(ReminderFragment.self),
        ] }
        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MoveReminderToListMutation.Data.MoveReminderToList.self,
          ReminderFragment.self
        ] }

        public var id: JoltAPI.UUID { __data["id"] }
        public var listId: JoltAPI.UUID? { __data["listId"] }
        public var title: String { __data["title"] }
        public var notes: String? { __data["notes"] }
        public var priority: GraphQLEnum<JoltAPI.Priority> { __data["priority"] }
        public var dueAt: JoltAPI.DateTime { __data["dueAt"] }
        public var allDay: Bool { __data["allDay"] }
        public var recurrenceRule: RecurrenceRule? { __data["recurrenceRule"] }
        public var recurrenceEnd: JoltAPI.DateTime? { __data["recurrenceEnd"] }
        public var status: GraphQLEnum<JoltAPI.ReminderStatus> { __data["status"] }
        public var completedAt: JoltAPI.DateTime? { __data["completedAt"] }
        public var snoozedUntil: JoltAPI.DateTime? { __data["snoozedUntil"] }
        public var snoozeCount: Int { __data["snoozeCount"] }
        public var tags: [String] { __data["tags"] }
        public var localId: String? { __data["localId"] }
        public var version: Int { __data["version"] }
        public var createdAt: JoltAPI.DateTime { __data["createdAt"] }
        public var updatedAt: JoltAPI.DateTime { __data["updatedAt"] }

        public struct Fragments: FragmentContainer {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public var reminderFragment: ReminderFragment { _toFragment() }
        }

        public typealias RecurrenceRule = ReminderFragment.RecurrenceRule
      }
    }
  }

}