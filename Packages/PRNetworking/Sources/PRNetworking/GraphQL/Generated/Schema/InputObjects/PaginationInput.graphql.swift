// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public extension PRAPI {
  struct PaginationInput: InputObject {
    public private(set) var __data: InputDict

    public init(_ data: InputDict) {
      __data = data
    }

    public init(
      first: GraphQLNullable<Int> = nil,
      after: GraphQLNullable<String> = nil,
      last: GraphQLNullable<Int> = nil,
      before: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "first": first,
        "after": after,
        "last": last,
        "before": before
      ])
    }

    public var first: GraphQLNullable<Int> {
      get { __data["first"] }
      set { __data["first"] = newValue }
    }

    public var after: GraphQLNullable<String> {
      get { __data["after"] }
      set { __data["after"] = newValue }
    }

    public var last: GraphQLNullable<Int> {
      get { __data["last"] }
      set { __data["last"] = newValue }
    }

    public var before: GraphQLNullable<String> {
      get { __data["before"] }
      set { __data["before"] = newValue }
    }
  }

}