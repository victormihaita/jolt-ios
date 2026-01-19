// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension JoltAPI {
  struct RecurrenceRuleInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
      frequency: GraphQLEnum<Frequency>,
      interval: Int,
      daysOfWeek: GraphQLNullable<[Int]> = nil,
      dayOfMonth: GraphQLNullable<Int> = nil,
      monthOfYear: GraphQLNullable<Int> = nil,
      endAfterOccurrences: GraphQLNullable<Int> = nil,
      endDate: GraphQLNullable<DateTime> = nil
    ) {
      __data = InputDict([
        "frequency": frequency,
        "interval": interval,
        "daysOfWeek": daysOfWeek,
        "dayOfMonth": dayOfMonth,
        "monthOfYear": monthOfYear,
        "endAfterOccurrences": endAfterOccurrences,
        "endDate": endDate
      ])
    }

    public var frequency: GraphQLEnum<Frequency> {
      get { __data["frequency"] }
      set { __data["frequency"] = newValue }
    }

    public var interval: Int {
      get { __data["interval"] }
      set { __data["interval"] = newValue }
    }

    public var daysOfWeek: GraphQLNullable<[Int]> {
      get { __data["daysOfWeek"] }
      set { __data["daysOfWeek"] = newValue }
    }

    public var dayOfMonth: GraphQLNullable<Int> {
      get { __data["dayOfMonth"] }
      set { __data["dayOfMonth"] = newValue }
    }

    public var monthOfYear: GraphQLNullable<Int> {
      get { __data["monthOfYear"] }
      set { __data["monthOfYear"] = newValue }
    }

    public var endAfterOccurrences: GraphQLNullable<Int> {
      get { __data["endAfterOccurrences"] }
      set { __data["endAfterOccurrences"] = newValue }
    }

    public var endDate: GraphQLNullable<DateTime> {
      get { __data["endDate"] }
      set { __data["endDate"] = newValue }
    }
  }

}