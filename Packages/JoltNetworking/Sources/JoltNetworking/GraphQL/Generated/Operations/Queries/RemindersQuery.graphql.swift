// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension JoltAPI {
  class RemindersQuery: GraphQLQuery {
    public static let operationName: String = "Reminders"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Reminders($filter: ReminderFilter, $pagination: PaginationInput) { reminders(filter: $filter, pagination: $pagination) { __typename edges { __typename node { __typename ...ReminderFragment } cursor } pageInfo { __typename hasNextPage hasPreviousPage startCursor endCursor } totalCount } }"#,
        fragments: [ReminderFragment.self]
      ))

    public var filter: GraphQLNullable<ReminderFilter>
    public var pagination: GraphQLNullable<PaginationInput>

    public init(
      filter: GraphQLNullable<ReminderFilter>,
      pagination: GraphQLNullable<PaginationInput>
    ) {
      self.filter = filter
      self.pagination = pagination
    }

    public var __variables: Variables? { [
      "filter": filter,
      "pagination": pagination
    ] }

    public struct Data: JoltAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.Query }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("reminders", Reminders.self, arguments: [
          "filter": .variable("filter"),
          "pagination": .variable("pagination")
        ]),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RemindersQuery.Data.self
      ] }

      public var reminders: Reminders { __data["reminders"] }

      /// Reminders
      ///
      /// Parent Type: `ReminderConnection`
      public struct Reminders: JoltAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.ReminderConnection }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("edges", [Edge].self),
          .field("pageInfo", PageInfo.self),
          .field("totalCount", Int.self),
        ] }
        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          RemindersQuery.Data.Reminders.self
        ] }

        public var edges: [Edge] { __data["edges"] }
        public var pageInfo: PageInfo { __data["pageInfo"] }
        public var totalCount: Int { __data["totalCount"] }

        /// Reminders.Edge
        ///
        /// Parent Type: `ReminderEdge`
        public struct Edge: JoltAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.ReminderEdge }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("node", Node.self),
            .field("cursor", String.self),
          ] }
          public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            RemindersQuery.Data.Reminders.Edge.self
          ] }

          public var node: Node { __data["node"] }
          public var cursor: String { __data["cursor"] }

          /// Reminders.Edge.Node
          ///
          /// Parent Type: `Reminder`
          public struct Node: JoltAPI.SelectionSet {
            public let __data: DataDict
            public init(_dataDict: DataDict) { __data = _dataDict }

            public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.Reminder }
            public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .fragment(ReminderFragment.self),
            ] }
            public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              RemindersQuery.Data.Reminders.Edge.Node.self,
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

        /// Reminders.PageInfo
        ///
        /// Parent Type: `PageInfo`
        public struct PageInfo: JoltAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.PageInfo }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("hasNextPage", Bool.self),
            .field("hasPreviousPage", Bool.self),
            .field("startCursor", String?.self),
            .field("endCursor", String?.self),
          ] }
          public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            RemindersQuery.Data.Reminders.PageInfo.self
          ] }

          public var hasNextPage: Bool { __data["hasNextPage"] }
          public var hasPreviousPage: Bool { __data["hasPreviousPage"] }
          public var startCursor: String? { __data["startCursor"] }
          public var endCursor: String? { __data["endCursor"] }
        }
      }
    }
  }

}