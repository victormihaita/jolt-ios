// @generated
// This file was automatically generated and can be edited to
// provide custom configuration for a generated GraphQL schema.
//
// Any changes to this file will not be overwritten by future
// code generation execution.

import ApolloAPI

public enum SchemaConfiguration: ApolloAPI.SchemaConfiguration {
    public static func cacheKeyInfo(for type: ApolloAPI.Object, object: ApolloAPI.ObjectData) -> CacheKeyInfo? {
        switch type {
        // Types with standard ID fields
        case PRAPI.Objects.User,
             PRAPI.Objects.Reminder,
             PRAPI.Objects.Device:
            return try? CacheKeyInfo(jsonValue: object["id"])

        // AuthPayload should not be cached (contains tokens)
        case PRAPI.Objects.AuthPayload:
            return nil

        // RecurrenceRule doesn't have an ID, cache by parent context
        case PRAPI.Objects.RecurrenceRule:
            return nil

        // PageInfo doesn't have an ID
        case PRAPI.Objects.PageInfo:
            return nil

        // ReminderChangeEvent is transient subscription data
        case PRAPI.Objects.ReminderChangeEvent:
            return nil

        // Handle Connection types - cache by first/last edge IDs
        case PRAPI.Objects.ReminderConnection:
            return handleConnection(object)

        // Handle Edge types - cache by node ID
        case PRAPI.Objects.ReminderEdge:
            return try? CacheKeyInfo(jsonValue: object["node"]?["id"], uniqueKeyGroup: "Edge")

        default:
            // Fallback: try to use "id" field if present
            return try? CacheKeyInfo(jsonValue: object["id"])
        }
    }

    private static func handleConnection(_ object: ApolloAPI.ObjectData, nodeKey: String = "id") -> CacheKeyInfo? {
        guard
            let edges = object._rawData["edges"] as? [AnyHashable],
            let firstValue = ((edges.first as? [String: AnyHashable])?["node"] as? [String: AnyHashable])?[nodeKey],
            let lastValue = ((edges.last as? [String: AnyHashable])?["node"] as? [String: AnyHashable])?[nodeKey]
        else { return nil }
        return try? CacheKeyInfo(jsonValue: "\(firstValue)-\(lastValue)", uniqueKeyGroup: "Connection")
    }
}
