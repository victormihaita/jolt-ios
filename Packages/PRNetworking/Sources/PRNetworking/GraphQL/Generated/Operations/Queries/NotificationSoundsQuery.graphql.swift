// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension PRAPI {
  class NotificationSoundsQuery: GraphQLQuery {
    public static let operationName: String = "NotificationSounds"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query NotificationSounds { notificationSounds { __typename id name filename isFree } }"#
      ))

    public init() {}

    public struct Data: PRAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { PRAPI.Objects.Query }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("notificationSounds", [NotificationSound].self),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        NotificationSoundsQuery.Data.self
      ] }

      public var notificationSounds: [NotificationSound] { __data["notificationSounds"] }

      /// NotificationSound
      ///
      /// Parent Type: `NotificationSound`
      public struct NotificationSound: PRAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { PRAPI.Objects.NotificationSound }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", PRAPI.UUID.self),
          .field("name", String.self),
          .field("filename", String.self),
          .field("isFree", Bool.self),
        ] }
        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          NotificationSoundsQuery.Data.NotificationSound.self
        ] }

        public var id: PRAPI.UUID { __data["id"] }
        public var name: String { __data["name"] }
        public var filename: String { __data["filename"] }
        public var isFree: Bool { __data["isFree"] }
      }
    }
  }

}