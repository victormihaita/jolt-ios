// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension JoltAPI {
  class ReminderListChangedSubscription: GraphQLSubscription {
    public static let operationName: String = "ReminderListChanged"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"subscription ReminderListChanged { reminderListChanged { __typename action reminderListId reminderList { __typename ...ReminderListFragment } timestamp } }"#,
        fragments: [ReminderListFragment.self]
      ))

    public init() {}

    public struct Data: JoltAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.Subscription }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("reminderListChanged", ReminderListChanged.self),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ReminderListChangedSubscription.Data.self
      ] }

      public var reminderListChanged: ReminderListChanged { __data["reminderListChanged"] }

      /// ReminderListChanged
      ///
      /// Parent Type: `ReminderListChangeEvent`
      public struct ReminderListChanged: JoltAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.ReminderListChangeEvent }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("action", GraphQLEnum<JoltAPI.ChangeAction>.self),
          .field("reminderListId", JoltAPI.UUID.self),
          .field("reminderList", ReminderList?.self),
          .field("timestamp", JoltAPI.DateTime.self),
        ] }
        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ReminderListChangedSubscription.Data.ReminderListChanged.self
        ] }

        public var action: GraphQLEnum<JoltAPI.ChangeAction> { __data["action"] }
        public var reminderListId: JoltAPI.UUID { __data["reminderListId"] }
        public var reminderList: ReminderList? { __data["reminderList"] }
        public var timestamp: JoltAPI.DateTime { __data["timestamp"] }

        /// ReminderListChanged.ReminderList
        ///
        /// Parent Type: `ReminderList`
        public struct ReminderList: JoltAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.ReminderList }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .fragment(ReminderListFragment.self),
          ] }
          public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            ReminderListChangedSubscription.Data.ReminderListChanged.ReminderList.self,
            ReminderListFragment.self
          ] }

          public var id: JoltAPI.UUID { __data["id"] }
          public var name: String { __data["name"] }
          public var colorHex: String { __data["colorHex"] }
          public var iconName: String { __data["iconName"] }
          public var sortOrder: Int { __data["sortOrder"] }
          public var isDefault: Bool { __data["isDefault"] }
          public var reminderCount: Int { __data["reminderCount"] }
          public var createdAt: JoltAPI.DateTime { __data["createdAt"] }
          public var updatedAt: JoltAPI.DateTime { __data["updatedAt"] }

          public struct Fragments: FragmentContainer {
            public let __data: DataDict
            public init(_dataDict: DataDict) { __data = _dataDict }

            public var reminderListFragment: ReminderListFragment { _toFragment() }
          }
        }
      }
    }
  }

}