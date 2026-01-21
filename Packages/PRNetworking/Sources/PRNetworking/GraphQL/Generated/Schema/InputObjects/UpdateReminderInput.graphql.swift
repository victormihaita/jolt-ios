// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension PRAPI {
  struct UpdateReminderInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
      listId: GraphQLNullable<UUID> = nil,
      title: GraphQLNullable<String> = nil,
      notes: GraphQLNullable<String> = nil,
      priority: GraphQLNullable<GraphQLEnum<Priority>> = nil,
      dueAt: GraphQLNullable<DateTime> = nil,
      allDay: GraphQLNullable<Bool> = nil,
      recurrenceRule: GraphQLNullable<RecurrenceRuleInput> = nil,
      recurrenceEnd: GraphQLNullable<DateTime> = nil,
      status: GraphQLNullable<GraphQLEnum<ReminderStatus>> = nil,
      tags: GraphQLNullable<[String]> = nil
    ) {
      __data = InputDict([
        "listId": listId,
        "title": title,
        "notes": notes,
        "priority": priority,
        "dueAt": dueAt,
        "allDay": allDay,
        "recurrenceRule": recurrenceRule,
        "recurrenceEnd": recurrenceEnd,
        "status": status,
        "tags": tags
      ])
    }

    public var listId: GraphQLNullable<UUID> {
      get { __data["listId"] }
      set { __data["listId"] = newValue }
    }

    public var title: GraphQLNullable<String> {
      get { __data["title"] }
      set { __data["title"] = newValue }
    }

    public var notes: GraphQLNullable<String> {
      get { __data["notes"] }
      set { __data["notes"] = newValue }
    }

    public var priority: GraphQLNullable<GraphQLEnum<Priority>> {
      get { __data["priority"] }
      set { __data["priority"] = newValue }
    }

    public var dueAt: GraphQLNullable<DateTime> {
      get { __data["dueAt"] }
      set { __data["dueAt"] = newValue }
    }

    public var allDay: GraphQLNullable<Bool> {
      get { __data["allDay"] }
      set { __data["allDay"] = newValue }
    }

    public var recurrenceRule: GraphQLNullable<RecurrenceRuleInput> {
      get { __data["recurrenceRule"] }
      set { __data["recurrenceRule"] = newValue }
    }

    public var recurrenceEnd: GraphQLNullable<DateTime> {
      get { __data["recurrenceEnd"] }
      set { __data["recurrenceEnd"] = newValue }
    }

    public var status: GraphQLNullable<GraphQLEnum<ReminderStatus>> {
      get { __data["status"] }
      set { __data["status"] = newValue }
    }

    public var tags: GraphQLNullable<[String]> {
      get { __data["tags"] }
      set { __data["tags"] = newValue }
    }
  }

}