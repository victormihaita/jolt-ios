// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public protocol JoltAPI_SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == JoltAPI.SchemaMetadata {}

public protocol JoltAPI_InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == JoltAPI.SchemaMetadata {}

public protocol JoltAPI_MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == JoltAPI.SchemaMetadata {}

public protocol JoltAPI_MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == JoltAPI.SchemaMetadata {}

public extension JoltAPI {
  typealias SelectionSet = JoltAPI_SelectionSet

  typealias InlineFragment = JoltAPI_InlineFragment

  typealias MutableSelectionSet = JoltAPI_MutableSelectionSet

  typealias MutableInlineFragment = JoltAPI_MutableInlineFragment

  enum SchemaMetadata: ApolloAPI.SchemaMetadata {
    public static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

    public static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
      switch typename {
      case "AuthPayload": return JoltAPI.Objects.AuthPayload
      case "Device": return JoltAPI.Objects.Device
      case "Mutation": return JoltAPI.Objects.Mutation
      case "PageInfo": return JoltAPI.Objects.PageInfo
      case "Query": return JoltAPI.Objects.Query
      case "RecurrenceRule": return JoltAPI.Objects.RecurrenceRule
      case "Reminder": return JoltAPI.Objects.Reminder
      case "ReminderChangeEvent": return JoltAPI.Objects.ReminderChangeEvent
      case "ReminderConnection": return JoltAPI.Objects.ReminderConnection
      case "ReminderEdge": return JoltAPI.Objects.ReminderEdge
      case "Subscription": return JoltAPI.Objects.Subscription
      case "User": return JoltAPI.Objects.User
      default: return nil
      }
    }
  }

  enum Objects {}
  enum Interfaces {}
  enum Unions {}

}