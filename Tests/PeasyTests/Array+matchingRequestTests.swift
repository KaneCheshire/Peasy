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
		XCTAssertNil(configs[invalidRequest])
		let validRequest = Request(method: .get, headers: [], path: "/", queryParameters: [], body: Data())
		XCTAssertEqual(configs[validRequest], configs.first!)
	}
	
	func test_multipleMatchingRequests_matchesLastAdded() {
		let configs: [Server.Configuration] = [.init(response: { _ in fatalError() }, rules: [.path(matches: "/"), .method(matches: .post)], removeAfterResponding: true),
                                               .init(response: { _ in fatalError() }, rules: [.path(matches: "/"), .method(matches: .get)], removeAfterResponding: true),
                                               .init(response: { _ in fatalError() }, rules: [.path(matches: "/"), .method(matches: .get)], removeAfterResponding: true),
                                               .init(response: { _ in fatalError() }, rules: [.path(matches: "/a"), .method(matches: .get)], removeAfterResponding: true)]
		let request = Request(method: .get, headers: [], path: "/", queryParameters: [], body: Data())
        XCTAssertNotEqual(configs[request], configs[0])
        XCTAssertNotEqual(configs[request], configs[1])
        XCTAssertEqual(configs[request], configs[2])
	}
	
}
