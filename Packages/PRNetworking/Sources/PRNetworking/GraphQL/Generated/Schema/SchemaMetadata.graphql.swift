// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public protocol PRAPI_SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == PRAPI.SchemaMetadata {}

public protocol PRAPI_InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == PRAPI.SchemaMetadata {}

public protocol PRAPI_MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == PRAPI.SchemaMetadata {}

public protocol PRAPI_MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == PRAPI.SchemaMetadata {}

public extension PRAPI {
  typealias SelectionSet = PRAPI_SelectionSet

  typealias InlineFragment = PRAPI_InlineFragment

  typealias MutableSelectionSet = PRAPI_MutableSelectionSet

  typealias MutableInlineFragment = PRAPI_MutableInlineFragment

  enum SchemaMetadata: ApolloAPI.SchemaMetadata {
    public static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

    public static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
      switch typename {
      case "AuthPayload": return PRAPI.Objects.AuthPayload
      case "Device": return PRAPI.Objects.Device
      case "Mutation": return PRAPI.Objects.Mutation
      case "NotificationSound": return PRAPI.Objects.NotificationSound
      case "PageInfo": return PRAPI.Objects.PageInfo
      case "Query": return PRAPI.Objects.Query
      case "RecurrenceRule": return PRAPI.Objects.RecurrenceRule
      case "Reminder": return PRAPI.Objects.Reminder
      case "ReminderChangeEvent": return PRAPI.Objects.ReminderChangeEvent
      case "ReminderConnection": return PRAPI.Objects.ReminderConnection
      case "ReminderEdge": return PRAPI.Objects.ReminderEdge
      case "ReminderList": return PRAPI.Objects.ReminderList
      case "ReminderListChangeEvent": return PRAPI.Objects.ReminderListChangeEvent
      case "Subscription": return PRAPI.Objects.Subscription
      case "User": return PRAPI.Objects.User
      default: return nil
      }
    }
  }

  enum Objects {}
  enum Interfaces {}
  enum Unions {}

}