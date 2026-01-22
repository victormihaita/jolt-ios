// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension PRAPI {
  struct RegisterDeviceInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
      platform: GraphQLEnum<Platform>,
      deviceIdentifier: String,
      pushToken: String,
      deviceName: GraphQLNullable<String> = nil,
      appVersion: GraphQLNullable<String> = nil,
      osVersion: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "platform": platform,
        "deviceIdentifier": deviceIdentifier,
        "pushToken": pushToken,
        "deviceName": deviceName,
        "appVersion": appVersion,
        "osVersion": osVersion
      ])
    }

    public var platform: GraphQLEnum<Platform> {
      get { __data["platform"] }
      set { __data["platform"] = newValue }
    }

    public var deviceIdentifier: String {
      get { __data["deviceIdentifier"] }
      set { __data["deviceIdentifier"] = newValue }
    }

    public var pushToken: String {
      get { __data["pushToken"] }
      set { __data["pushToken"] = newValue }
    }

    public var deviceName: GraphQLNullable<String> {
      get { __data["deviceName"] }
      set { __data["deviceName"] = newValue }
    }

    public var appVersion: GraphQLNullable<String> {
      get { __data["appVersion"] }
      set { __data["appVersion"] = newValue }
    }

    public var osVersion: GraphQLNullable<String> {
      get { __data["osVersion"] }
      set { __data["osVersion"] = newValue }
    }
  }

}