//
//  Array+matchingRequestTests.swift
//  
//
//  Created by Kane Cheshire on 05/12/2019.
//

import XCTest
@testable import Peasy

final class Array_matchingRequestTests: XCTestCase {
	
	func test_noMatchingRequest() {
		let configs: [Server.Configuration] = [.init(response: { _ in fatalError() }, rules: [.path(matches: "/"), .method(matches: .get)], removeAfterResponding: true)]
		let invalidRequest = Request(method: .post, headers: [], path: "/", queryParameters: [], body: Data())
		XCTAssertNil(configs.matching(invalidRequest))
		let validRequest = Request(method: .get, headers: [], path: "/", queryParameters: [], body: Data())
		XCTAssertEqual(configs.matching(validRequest), configs.first!)
	}
	
	func test_multipleMatchingRequests() {
		let configs: [Server.Configuration] = [.init(response: { _ in fatalError() }, rules: [.path(matches: "/"), .method(matches: .post)], removeAfterResponding: true),
																					 .init(response: { _ in fatalError() }, rules: [.path(matches: "/"), .method(matches: .get)], removeAfterResponding: true),
																					 .init(response: { _ in fatalError() }, rules: [.path(matches: "/"), .method(matches: .get)], removeAfterResponding: true)]
		let request = Request(method: .get, headers: [], path: "/", queryParameters: [], body: Data())
		XCTAssertEqual(configs.matching(request), configs[1])
		XCTAssertNotEqual(configs.matching(request), configs[2])
	}
	
}
