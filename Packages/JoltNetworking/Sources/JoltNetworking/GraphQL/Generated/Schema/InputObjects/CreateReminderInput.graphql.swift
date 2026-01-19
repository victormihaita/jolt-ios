// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension JoltAPI {
  struct CreateReminderInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
      title: String,
      notes: GraphQLNullable<String> = nil,
      priority: GraphQLNullable<GraphQLEnum<Priority>> = nil,
      dueAt: DateTime,
      allDay: Bool,
      recurrenceRule: GraphQLNullable<RecurrenceRuleInput> = nil,
      recurrenceEnd: GraphQLNullable<DateTime> = nil,
      localId: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "title": title,
        "notes": notes,
        "priority": priority,
        "dueAt": dueAt,
        "allDay": allDay,
        "recurrenceRule": recurrenceRule,
        "recurrenceEnd": recurrenceEnd,
        "localId": localId
      ])
    }

    public var title: String {
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

    public var dueAt: DateTime {
      get { __data["dueAt"] }
      set { __data["dueAt"] = newValue }
    }

    public var allDay: Bool {
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

    public var localId: GraphQLNullable<String> {
      get { __data["localId"] }
      set { __data["localId"] = newValue }
    }
  }

}