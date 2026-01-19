// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension JoltAPI {
  class UnregisterDeviceMutation: GraphQLMutation {
    public static let operationName: String = "UnregisterDevice"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation UnregisterDevice($id: UUID!) { unregisterDevice(id: $id) }"#
      ))

    public var id: UUID

    public init(id: UUID) {
      self.id = id
    }

    public var __variables: Variables? { ["id": id] }

    public struct Data: JoltAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { JoltAPI.Objects.Mutation }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("unregisterDevice", Bool.self, arguments: ["id": .variable("id")]),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        UnregisterDeviceMutation.Data.self
      ] }

      public var unregisterDevice: Bool { __data["unregisterDevice"] }
    }
  }

}