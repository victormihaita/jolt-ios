// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension JoltAPI {
  class ReminderChangedSubscription: GraphQLSubscription {
    public static let operationName: String = "ReminderChanged"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"subscription ReminderChanged { reminderChanged { __typename action reminder { __typename ...ReminderFragment } reminderId timestamp } }"#,
        fragments: [ReminderFragment.self]
      ))

    public init() {}

    public struct Data: JoltAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.Subscription }
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
      public struct ReminderChanged: JoltAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.ReminderChangeEvent }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("action", GraphQLEnum<JoltAPI.ChangeAction>.self),
          .field("reminder", Reminder?.self),
          .field("reminderId", JoltAPI.UUID.self),
          .field("timestamp", JoltAPI.DateTime.self),
        ] }
        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ReminderChangedSubscription.Data.ReminderChanged.self
        ] }

        public var action: GraphQLEnum<JoltAPI.ChangeAction> { __data["action"] }
        public var reminder: Reminder? { __data["reminder"] }
        public var reminderId: JoltAPI.UUID { __data["reminderId"] }
        public var timestamp: JoltAPI.DateTime { __data["timestamp"] }

        /// ReminderChanged.Reminder
        ///
        /// Parent Type: `Reminder`
        public struct Reminder: JoltAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.Reminder }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .fragment(ReminderFragment.self),
          ] }
          public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ReminderChangedSubscription.Data.ReminderChanged.Reminder.self,
            ReminderFragment.self
          ] }

          public var id: JoltAPI.UUID { __data["id"] }
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

}