// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension PRAPI {
  class DevicesQuery: GraphQLQuery {
    public static let operationName: String = "Devices"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Devices { devices { __typename id platform deviceName appVersion osVersion lastSeenAt createdAt } }"#
      ))

    public init() {}

    public struct Data: PRAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { PRAPI.Objects.Query }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("devices", [Device].self),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DevicesQuery.Data.self
      ] }

      public var devices: [Device] { __data["devices"] }

      /// Device
      ///
      /// Parent Type: `Device`
      public struct Device: PRAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { PRAPI.Objects.Device }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", PRAPI.UUID.self),
          .field("platform", GraphQLEnum<PRAPI.Platform>.self),
          .field("deviceName", String?.self),
          .field("appVersion", String?.self),
          .field("osVersion", String?.self),
          .field("lastSeenAt", PRAPI.DateTime.self),
          .field("createdAt", PRAPI.DateTime.self),
        ] }
        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          DevicesQuery.Data.Device.self
        ] }

        public var id: PRAPI.UUID { __data["id"] }
        public var platform: GraphQLEnum<PRAPI.Platform> { __data["platform"] }
        public var deviceName: String? { __data["deviceName"] }
        public var appVersion: String? { __data["appVersion"] }
        public var osVersion: String? { __data["osVersion"] }
        public var lastSeenAt: PRAPI.DateTime { __data["lastSeenAt"] }
        public var createdAt: PRAPI.DateTime { __data["createdAt"] }
      }
    }
  }

}