// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension JoltAPI {
  class RegisterDeviceMutation: GraphQLMutation {
    public static let operationName: String = "RegisterDevice"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation RegisterDevice($input: RegisterDeviceInput!) { registerDevice(input: $input) { __typename id platform deviceName appVersion osVersion lastSeenAt createdAt } }"#
      ))

    public var input: RegisterDeviceInput

    public init(input: RegisterDeviceInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    public struct Data: JoltAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.Mutation }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("registerDevice", RegisterDevice.self, arguments: ["input": .variable("input")]),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RegisterDeviceMutation.Data.self
      ] }

      public var registerDevice: RegisterDevice { __data["registerDevice"] }

      /// RegisterDevice
      ///
      /// Parent Type: `Device`
      public struct RegisterDevice: JoltAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.Device }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", JoltAPI.UUID.self),
          .field("platform", GraphQLEnum<JoltAPI.Platform>.self),
          .field("deviceName", String?.self),
          .field("appVersion", String?.self),
          .field("osVersion", String?.self),
          .field("lastSeenAt", JoltAPI.DateTime.self),
          .field("createdAt", JoltAPI.DateTime.self),
        ] }
        public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          RegisterDeviceMutation.Data.RegisterDevice.self
        ] }

        public var id: JoltAPI.UUID { __data["id"] }
        public var platform: GraphQLEnum<JoltAPI.Platform> { __data["platform"] }
        public var deviceName: String? { __data["deviceName"] }
        public var appVersion: String? { __data["appVersion"] }
        public var osVersion: String? { __data["osVersion"] }
        public var lastSeenAt: JoltAPI.DateTime { __data["lastSeenAt"] }
        public var createdAt: JoltAPI.DateTime { __data["createdAt"] }
      }
    }
  }

}