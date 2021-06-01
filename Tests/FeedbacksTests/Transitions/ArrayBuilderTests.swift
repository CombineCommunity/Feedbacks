//
//  ArrayBuilderTests.swift
//  
//
//  Created by Thibault Wittemberg on 2021-02-21.
//

import Feedbacks
import XCTest

final class ArrayBuilderTests: XCTestCase {
    @ArrayBuilder<Int>
    var mockEntries: [Int] {
        1
        2
        3
        4
        5
    }

    func testBuildBlock_gathers_entries_into_an_array() {
        XCTAssertEqual(self.mockEntries, [1, 2, 3, 4, 5])

    }
}
