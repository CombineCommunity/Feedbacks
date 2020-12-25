//
//  StaticIdentifiableTests.swift
//
//
//  Created by Thibault Wittemberg on 2020-12-24.
//

import Feedbacks
import XCTest

private struct MockIdentifiable: StaticIdentifiable {}

final class StaticIdentifiableTests: XCTestCase {
    func testId_return_string_reflecting_type() {
        // Given: a type implementing StaticIdentifiable
        // When: getting the static id
        // Then: the id is the String reflecting the type
        XCTAssertEqual(MockIdentifiable.id, String(reflecting: MockIdentifiable.self))
    }

    func testInstanceId_is_equal_to_static_id() {
        // Given: an instance of a StaticIdentifiable
        let mockIdentifiable = MockIdentifiable()

        // When: getting the instance id
        // Then: the instance id is equal to the static id
        XCTAssertEqual(mockIdentifiable.instanceId, MockIdentifiable.id)
    }
}
