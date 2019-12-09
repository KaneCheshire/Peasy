//
//  Array+variableIndicesTests.swift
//  
//
//  Created by Kane Cheshire on 05/12/2019.
//

import XCTest
@testable import Peasy

final class Array_variableIndicesTests: XCTestCase {
	
	func test_noIndices() {
		let components: [String] = ["", ":", "a", "*"]
		XCTAssertEqual(components.variableIndices, [])
	}
	
	func test_indices() {
		let components: [String] = ["a", ":b", ":c", "d", ":efg:", "h:"]
		XCTAssertEqual(components.variableIndices, [1, 2, 4])
	}
	
}
