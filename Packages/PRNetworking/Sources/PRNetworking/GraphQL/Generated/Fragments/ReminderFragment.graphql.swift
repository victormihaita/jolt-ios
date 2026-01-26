// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension PRAPI {
  struct ReminderFragment: PRAPI.SelectionSet, Fragment {
    public static var fragmentDefinition: StaticString {
      #"fragment ReminderFragment on Reminder { __typename id listId title notes priority dueAt allDay isAlarm soundId recurrenceRule { __typename frequency interval daysOfWeek dayOfMonth monthOfYear endAfterOccurrences endDate } recurrenceEnd status completedAt snoozedUntil snoozeCount tags localId version createdAt updatedAt }"#
    }

    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { PRAPI.Objects.Reminder }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("__typename", String.self),
      .field("id", PRAPI.UUID.self),
      .field("listId", PRAPI.UUID?.self),
      .field("title", String.self),
      .field("notes", String?.self),
      .field("priority", GraphQLEnum<PRAPI.Priority>.self),
      .field("dueAt", PRAPI.DateTime?.self),
      .field("allDay", Bool?.self),
      .field("isAlarm", Bool.self),
      .field("soundId", String?.self),
      .field("recurrenceRule", RecurrenceRule?.self),
      .field("recurrenceEnd", PRAPI.DateTime?.self),
      .field("status", GraphQLEnum<PRAPI.ReminderStatus>.self),
      .field("completedAt", PRAPI.DateTime?.self),
      .field("snoozedUntil", PRAPI.DateTime?.self),
      .field("snoozeCount", Int.self),
      .field("tags", [String].self),
      .field("localId", String?.self),
      .field("version", Int.self),
      .field("createdAt", PRAPI.DateTime.self),
      .field("updatedAt", PRAPI.DateTime.self),
    ] }
    public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
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

    /// RecurrenceRule
    ///
    /// Parent Type: `RecurrenceRule`
    public struct RecurrenceRule: PRAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { PRAPI.Objects.RecurrenceRule }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("frequency", GraphQLEnum<PRAPI.Frequency>.self),
        .field("interval", Int.self),
        .field("daysOfWeek", [Int]?.self),
        .field("dayOfMonth", Int?.self),
        .field("monthOfYear", Int?.self),
        .field("endAfterOccurrences", Int?.self),
        .field("endDate", PRAPI.DateTime?.self),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ReminderFragment.RecurrenceRule.self
      ] }

      public var frequency: GraphQLEnum<PRAPI.Frequency> { __data["frequency"] }
      public var interval: Int { __data["interval"] }
      public var daysOfWeek: [Int]? { __data["daysOfWeek"] }
      public var dayOfMonth: Int? { __data["dayOfMonth"] }
      public var monthOfYear: Int? { __data["monthOfYear"] }
      public var endAfterOccurrences: Int? { __data["endAfterOccurrences"] }
      public var endDate: PRAPI.DateTime? { __data["endDate"] }
    }
  }

}