// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension JoltAPI {
  struct ReminderFragment: JoltAPI.SelectionSet, Fragment {
    public static var fragmentDefinition: StaticString {
      #"fragment ReminderFragment on Reminder { __typename id listId title notes priority dueAt allDay recurrenceRule { __typename frequency interval daysOfWeek dayOfMonth monthOfYear endAfterOccurrences endDate } recurrenceEnd status completedAt snoozedUntil snoozeCount tags localId version createdAt updatedAt }"#
    }

    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.Reminder }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("__typename", String.self),
      .field("id", JoltAPI.UUID.self),
      .field("listId", JoltAPI.UUID?.self),
      .field("title", String.self),
      .field("notes", String?.self),
      .field("priority", GraphQLEnum<JoltAPI.Priority>.self),
      .field("dueAt", JoltAPI.DateTime.self),
      .field("allDay", Bool.self),
      .field("recurrenceRule", RecurrenceRule?.self),
      .field("recurrenceEnd", JoltAPI.DateTime?.self),
      .field("status", GraphQLEnum<JoltAPI.ReminderStatus>.self),
      .field("completedAt", JoltAPI.DateTime?.self),
      .field("snoozedUntil", JoltAPI.DateTime?.self),
      .field("snoozeCount", Int.self),
      .field("tags", [String].self),
      .field("localId", String?.self),
      .field("version", Int.self),
      .field("createdAt", JoltAPI.DateTime.self),
      .field("updatedAt", JoltAPI.DateTime.self),
    ] }
    public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
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

    /// RecurrenceRule
    ///
    /// Parent Type: `RecurrenceRule`
    public struct RecurrenceRule: JoltAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.RecurrenceRule }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("frequency", GraphQLEnum<JoltAPI.Frequency>.self),
        .field("interval", Int.self),
        .field("daysOfWeek", [Int]?.self),
        .field("dayOfMonth", Int?.self),
        .field("monthOfYear", Int?.self),
        .field("endAfterOccurrences", Int?.self),
        .field("endDate", JoltAPI.DateTime?.self),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ReminderFragment.RecurrenceRule.self
      ] }

      public var frequency: GraphQLEnum<JoltAPI.Frequency> { __data["frequency"] }
      public var interval: Int { __data["interval"] }
      public var daysOfWeek: [Int]? { __data["daysOfWeek"] }
      public var dayOfMonth: Int? { __data["dayOfMonth"] }
      public var monthOfYear: Int? { __data["monthOfYear"] }
      public var endAfterOccurrences: Int? { __data["endAfterOccurrences"] }
      public var endDate: JoltAPI.DateTime? { __data["endDate"] }
    }
  }

}