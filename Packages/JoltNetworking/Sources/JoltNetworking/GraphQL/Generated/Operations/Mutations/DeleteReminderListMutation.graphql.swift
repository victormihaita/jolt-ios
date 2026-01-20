// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public extension JoltAPI {
  class DeleteReminderListMutation: GraphQLMutation {
    public static let operationName: String = "DeleteReminderList"
    public static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation DeleteReminderList($id: UUID!) { deleteReminderList(id: $id) }"#
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
        .field("deleteReminderList", Bool.self, arguments: ["id": .variable("id")]),
      ] }
      public static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DeleteReminderListMutation.Data.self
      ] }

      public var deleteReminderList: Bool { __data["deleteReminderList"] }
    }
  }

}