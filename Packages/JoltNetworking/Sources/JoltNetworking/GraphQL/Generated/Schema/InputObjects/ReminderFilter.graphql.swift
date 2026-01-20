// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension JoltAPI {
  struct ReminderFilter: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
      listId: GraphQLNullable<UUID> = nil,
      status: GraphQLNullable<GraphQLEnum<ReminderStatus>> = nil,
      fromDate: GraphQLNullable<DateTime> = nil,
      toDate: GraphQLNullable<DateTime> = nil,
      priority: GraphQLNullable<GraphQLEnum<Priority>> = nil,
      tags: GraphQLNullable<[String]> = nil
    ) {
      __data = InputDict([
        "listId": listId,
        "status": status,
        "fromDate": fromDate,
        "toDate": toDate,
        "priority": priority,
        "tags": tags
      ])
    }

    public var listId: GraphQLNullable<UUID> {
      get { __data["listId"] }
      set { __data["listId"] = newValue }
    }

    public var status: GraphQLNullable<GraphQLEnum<ReminderStatus>> {
      get { __data["status"] }
      set { __data["status"] = newValue }
    }

    public var fromDate: GraphQLNullable<DateTime> {
      get { __data["fromDate"] }
      set { __data["fromDate"] = newValue }
    }

    public var toDate: GraphQLNullable<DateTime> {
      get { __data["toDate"] }
      set { __data["toDate"] = newValue }
    }

    public var priority: GraphQLNullable<GraphQLEnum<Priority>> {
      get { __data["priority"] }
      set { __data["priority"] = newValue }
    }

    public var tags: GraphQLNullable<[String]> {
      get { __data["tags"] }
      set { __data["tags"] = newValue }
    }
  }

}