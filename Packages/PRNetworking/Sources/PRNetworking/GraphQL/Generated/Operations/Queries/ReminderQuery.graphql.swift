// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension PRAPI {
  class ReminderQuery: GraphQLQuery {
    public static let operationName: String = "Reminder"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Reminder($id: UUID!) { reminder(id: $id) { __typename ...ReminderFragment } }"#,
        fragments: [ReminderFragment.self]
      ))

    public var id: UUID

    public init(id: UUID) {
      self.id = id
    }

    public var __variables: Variables? { ["id": id] }

    public struct Data: PRAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { PRAPI.Objects.Query }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("reminder", Reminder?.self, arguments: ["id": .variable("id")]),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ReminderQuery.Data.self
      ] }

      public var reminder: Reminder? { __data["reminder"] }

      /// Reminder
      ///
      /// Parent Type: `Reminder`
      public struct Reminder: PRAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { PRAPI.Objects.Reminder }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .fragment(ReminderFragment.self),
        ] }
        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ReminderQuery.Data.Reminder.self,
          ReminderFragment.self
        ] }

        public var id: PRAPI.UUID { __data["id"] }
        public var listId: PRAPI.UUID? { __data["listId"] }
        public var title: String { __data["title"] }
        public var notes: String? { __data["notes"] }
        public var priority: GraphQLEnum<PRAPI.Priority> { __data["priority"] }
        public var dueAt: PRAPI.DateTime { __data["dueAt"] }
        public var allDay: Bool { __data["allDay"] }
        public var isAlarm: Bool { __data["isAlarm"] }
        public var recurrenceRule: RecurrenceRule? { __data["recurrenceRule"] }
        public var recurrenceEnd: PRAPI.DateTime? { __data["recurrenceEnd"] }
        public var status: GraphQLEnum<PRAPI.ReminderStatus> { __data["status"] }
        public var completedAt: PRAPI.DateTime? { __data["completedAt"] }
        public var snoozedUntil: PRAPI.DateTime? { __data["snoozedUntil"] }
        public var snoozeCount: Int { __data["snoozeCount"] }
        public var tags: [String] { __data["tags"] }
        public var localId: String? { __data["localId"] }
        public var version: Int { __data["version"] }
        public var createdAt: PRAPI.DateTime { __data["createdAt"] }
        public var updatedAt: PRAPI.DateTime { __data["updatedAt"] }

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