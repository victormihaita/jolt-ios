// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension PRAPI {
  class ReminderChangedSubscription: GraphQLSubscription {
    public static let operationName: String = "ReminderChanged"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"subscription ReminderChanged { reminderChanged { __typename action reminder { __typename ...ReminderFragment } reminderId timestamp } }"#,
        fragments: [ReminderFragment.self]
      ))

    public init() {}

    public struct Data: PRAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { PRAPI.Objects.Subscription }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("reminderChanged", ReminderChanged.self),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ReminderChangedSubscription.Data.self
      ] }

      public var reminderChanged: ReminderChanged { __data["reminderChanged"] }

      /// ReminderChanged
      ///
      /// Parent Type: `ReminderChangeEvent`
      public struct ReminderChanged: PRAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { PRAPI.Objects.ReminderChangeEvent }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("action", GraphQLEnum<PRAPI.ChangeAction>.self),
          .field("reminder", Reminder?.self),
          .field("reminderId", PRAPI.UUID.self),
          .field("timestamp", PRAPI.DateTime.self),
        ] }
        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ReminderChangedSubscription.Data.ReminderChanged.self
        ] }

        public var action: GraphQLEnum<PRAPI.ChangeAction> { __data["action"] }
        public var reminder: Reminder? { __data["reminder"] }
        public var reminderId: PRAPI.UUID { __data["reminderId"] }
        public var timestamp: PRAPI.DateTime { __data["timestamp"] }

        /// ReminderChanged.Reminder
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
            ReminderChangedSubscription.Data.ReminderChanged.Reminder.self,
            ReminderFragment.self
          ] }

          public var id: PRAPI.UUID { __data["id"] }
          public var listId: PRAPI.UUID? { __data["listId"] }
          public var title: String { __data["title"] }
          public var notes: String? { __data["notes"] }
          public var priority: GraphQLEnum<PRAPI.Priority> { __data["priority"] }
          public var dueAt: PRAPI.DateTime? { __data["dueAt"] }
          public var allDay: Bool? { __data["allDay"] }
          public var isAlarm: Bool { __data["isAlarm"] }
          public var soundId: String? { __data["soundId"] }
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

}