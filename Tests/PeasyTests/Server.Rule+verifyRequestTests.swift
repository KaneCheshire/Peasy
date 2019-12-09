//
//  Server.Rule+verifyRequestTests.swift
//  
//
//  Created by Kane Cheshire on 05/12/2019.
//

import XCTest
@testable import Peasy

final class ServerRule_verifyRequestTests: XCTestCase {
	
	func test_verifyMethodMatches() {
		let req = Request(method: .get, headers: [], path: "", queryParameters: [], body: Data())
		XCTAssertTrue(Server.Rule.method(matches: .get).verify(req))
		XCTAssertFalse(Server.Rule.method(matches: .post).verify(req))
	}
	
	func test_verifyHeadersContain() {
		let header = Request.Header(name: .userAgent, value: "heya")
		let req = Request(method: .get, headers: [header], path: "", queryParameters: [], body: Data())
		XCTAssertTrue(Server.Rule.headers(contain: header).verify(req))
		XCTAssertFalse(Server.Rule.headers(contain: .init(name: .userAgent, value: "hola")).verify(req))
	}
	
	func test_verifyQueryContain() {
		let param = Request.QueryParameter(name: "hi", value: "there")
		let req = Request(method: .get, headers: [], path: "", queryParameters: [param], body: Data())
		XCTAssertTrue(Server.Rule.queryParameters(contain: param).verify(req))
		XCTAssertFalse(Server.Rule.queryParameters(contain: .init(name: "hiya", value: "you")).verify(req))
	}
	
	func test_verifyBodyMatches() {
		let body = Data("hello".utf8)
		let req = Request(method: .get, headers: [], path: "", queryParameters: [], body: body)
		XCTAssertTrue(Server.Rule.body(matches: body).verify(req))
		XCTAssertFalse(Server.Rule.body(matches: Data("yo".utf8)).verify(req))
	}
	
	func test_verifyCustom() {
		let req = Request(method: .get, headers: [], path: "", queryParameters: [], body: Data())
		XCTAssertTrue(Server.Rule.custom({ _ in true }).verify(req))
		XCTAssertFalse(Server.Rule.custom({ _ in false }).verify(req))
	}
	
	func test_verifyPath() {
		let reqA = Request(method: .get, headers: [], path: "", queryParameters: [], body: Data())
		XCTAssertTrue(Server.Rule.path(matches: "").verify(reqA))
		XCTAssertTrue(Server.Rule.path(matches: "/").verify(reqA)) // TODO: Not really expected behaviour
		
		let reqB = Request(method: .get, headers: [], path: "/a/b/c", queryParameters: [], body: Data())
		XCTAssertTrue(Server.Rule.path(matches: "/a/b/c").verify(reqB))
		XCTAssertFalse(Server.Rule.path(matches: "/a/c").verify(reqB))
		XCTAssertFalse(Server.Rule.path(matches: "/a/b/").verify(reqB))
		XCTAssertTrue(Server.Rule.path(matches: "/a/b/c/").verify(reqB))
		XCTAssertTrue(Server.Rule.path(matches: "a/b/c/").verify(reqB))
		XCTAssertTrue(Server.Rule.path(matches: "a/b/c").verify(reqB))
		
		let reqC = Request(method: .get, headers: [], path: "/x/y/z", queryParameters: [], body: Data())
		XCTAssertTrue(Server.Rule.path(matches: "/:a/:b/:c").verify(reqC))
		XCTAssertTrue(Server.Rule.path(matches: "/:a/:b/z").verify(reqC))
		XCTAssertTrue(Server.Rule.path(matches: "/:a/y/z").verify(reqC))
		XCTAssertTrue(Server.Rule.path(matches: "/x/:b/:c").verify(reqC))
		XCTAssertTrue(Server.Rule.path(matches: "/x/y/:c").verify(reqC))
		XCTAssertTrue(Server.Rule.path(matches: "/x/y/z").verify(reqC))
		XCTAssertFalse(Server.Rule.path(matches: "/:a/:b/c").verify(reqC))
		XCTAssertFalse(Server.Rule.path(matches: "/:a/:b/").verify(reqC))
	}
	
}
