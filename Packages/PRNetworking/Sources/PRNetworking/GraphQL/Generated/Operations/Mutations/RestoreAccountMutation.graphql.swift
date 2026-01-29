// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension PRAPI {
  class RestoreAccountMutation: GraphQLMutation {
    public static let operationName: String = "RestoreAccount"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation RestoreAccount { restoreAccount }"#
      ))

    public init() {}

    public struct Data: PRAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { PRAPI.Objects.Mutation }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("restoreAccount", Bool.self),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        RestoreAccountMutation.Data.self
      ] }

      public var restoreAccount: Bool { __data["restoreAccount"] }
    }
  }

}