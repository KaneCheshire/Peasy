//
//  URL+variableValuesTests.swift
//  
//
//  Created by Kane Cheshire on 05/12/2019.
//

import XCTest
@testable import Peasy

final class URL_variableValuesTests: XCTestCase {
	
	func test_noVariables() {
		XCTAssertEqual(URL(string: "/a/b/c")!.variableValues(from: URL(string: "/a/b/c")!), [:])
		XCTAssertEqual(URL(string: "/")!.variableValues(from: URL(string: "/")!), [:])
	}
	
	func test_variable() {
		XCTAssertEqual(URL(string: "/x/y/z")!.variableValues(from: URL(string: "/a/:b/c")!), ["b":"y"])
		XCTAssertEqual(URL(string: "/x//z")!.variableValues(from: URL(string: "/a/:b/c")!), [:])
		XCTAssertEqual(URL(string: "/x/z")!.variableValues(from: URL(string: "/a/:b/c")!), [:])
		let a = URL(string: "/x/y/z")!.variableValues(from: URL(string: "/:a/:b/:c")!)
		XCTAssertEqual(a.count, 3)
		XCTAssertEqual(a["a"], "x")
		XCTAssertEqual(a["b"], "y")
		XCTAssertEqual(a["c"], "z")
		
		let b = URL(string: "/x/y/z")!.variableValues(from: URL(string: "/:a/:a/:b")!)
		XCTAssertEqual(b.count, 2)
		XCTAssertEqual(b["a"], "y")
		XCTAssertEqual(b["b"], "z")
	}
	
}
