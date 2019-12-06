//
//  RequestParserTests.swift
//  
//
//  Created by Kane Cheshire on 06/12/2019.
//

import XCTest
@testable import Peasy

final class RequestParserTests: XCTestCase {
	
	var parser: RequestParser!
	
	override func setUp() {
		parser = RequestParser()
	}
	
	func test_parsingIncrementally_withContentLength_get() {
		guard case .receivingHeader = parser.parse(Data()) else { return XCTFail("Wrong state") }
		guard case .receivingHeader = parser.parse(Data("GET ")) else { return XCTFail("Wrong state") }
		guard case .receivingHeader = parser.parse(Data("/path?query=param&another=query\r\n")) else { return XCTFail("Wrong state") }
		guard case .receivingHeader = parser.parse(Data("Header: Value\r\nContent-Length: 2")) else { return XCTFail("Wrong state") }
		guard case .receivingBody(fullHeader: let fullHeader, partialBody: let partialBody, progress: let progress) = parser.parse(Data("\r\n\r\n")) else { return XCTFail("Wrong state") } // TODO: What happens if these are split over two events?
		XCTAssertEqual(fullHeader, Data("GET /path?query=param&another=query\r\nHeader: Value\r\nContent-Length: 2"))
		XCTAssertEqual(partialBody, Data())
		XCTAssertEqual(progress, 0)
		guard case .receivingBody(fullHeader: let fullHeaderB, partialBody: let partialBodyB, progress: let progressB) = parser.parse(Data("1")) else { return XCTFail("Wrong state") }
		XCTAssertEqual(fullHeaderB, Data("GET /path?query=param&another=query\r\nHeader: Value\r\nContent-Length: 2"))
		XCTAssertEqual(partialBodyB, Data("1"))
		XCTAssertEqual(progressB, 0.5)
		guard case .finished(let request) = parser.parse(Data("2")) else { return XCTFail("Wrong state") }
		XCTAssertEqual(request.method, .get)
		XCTAssertEqual(request.path, "/path")
		XCTAssertEqual(request.queryParameters, [.init(name: "query", value: "param"), .init(name: "another", value: "query")])
		XCTAssertEqual(request.headers, [.init(name: "Header", value: "Value"), .init(name: "Content-Length", value: "2")])
		XCTAssertEqual(request.body, Data("12"))
	}
	
	func test_parsingIncrementally_withContentLength_post() {
		guard case .receivingHeader = parser.parse(Data()) else { return XCTFail("Wrong state") }
		guard case .receivingHeader = parser.parse(Data("POST")) else { return XCTFail("Wrong state") }
		guard case .receivingHeader = parser.parse(Data(" /?\r\n")) else { return XCTFail("Wrong state") }
		guard case .receivingBody(fullHeader: let fullHeader, partialBody: let partialBody, progress: let progress) = parser.parse(Data("Content-Length: 3\r\n\r\n")) else { return XCTFail("Wrong state") }
		XCTAssertEqual(fullHeader, Data("POST /?\r\nContent-Length: 3"))
		XCTAssertEqual(partialBody, Data())
		XCTAssertEqual(progress, 0)
		guard case .receivingBody(fullHeader: let fullHeaderB, partialBody: let partialBodyB, progress: let progressB) = parser.parse(Data("1")) else { return XCTFail("Wrong state") }
		XCTAssertEqual(fullHeaderB, Data("POST /?\r\nContent-Length: 3"))
		XCTAssertEqual(partialBodyB, Data("1"))
		XCTAssertEqual(progressB, 0.33333334)
		guard case .receivingBody(fullHeader: let fullHeaderC, partialBody: let partialBodyC, progress: let progressC) = parser.parse(Data("2")) else { return XCTFail("Wrong state") }
		XCTAssertEqual(fullHeaderC, Data("POST /?\r\nContent-Length: 3"))
		XCTAssertEqual(partialBodyC, Data("12"))
		XCTAssertEqual(progressC, 0.6666667)
		guard case .finished(let request) = parser.parse(Data("3")) else { return XCTFail("Wrong state") }
		XCTAssertEqual(request.method, .post)
		XCTAssertEqual(request.path, "/")
		XCTAssertEqual(request.queryParameters, [])
		XCTAssertEqual(request.headers, [.init(name: "Content-Length", value: "3")])
		XCTAssertEqual(request.body, Data("123"))
	}
	
	func test_parsingDataOverSpecifiedContentLength() {
		guard case .receivingBody(fullHeader: let fullHeader, partialBody: let partialBody, progress: let progress) = parser.parse(Data("PUT / \r\nContent-Length: 1\r\n\r\n")) else { return XCTFail("Wrong state") }
		XCTAssertEqual(fullHeader, Data("PUT / \r\nContent-Length: 1"))
		XCTAssertEqual(partialBody, Data(""))
		XCTAssertEqual(progress, 0)
		guard case .finished(let request) = parser.parse(Data("123")) else { return XCTFail("Wrong state") }
		XCTAssertEqual(request.method, .put)
		XCTAssertEqual(request.path, "/")
		XCTAssertEqual(request.queryParameters, [])
		XCTAssertEqual(request.headers, [.init(name: "Content-Length", value: "1")])
		XCTAssertEqual(request.body, Data("123"))
	}
	
	func test_parsingWithBodyIncludedInHeaderBreak() {
		guard case .receivingBody(fullHeader: let fullHeader, partialBody: let partialBody, progress: let progress) = parser.parse(Data("DELETE / \r\nContent-Length: 2\r\n\r\n1")) else { return XCTFail("Wrong state") }
		XCTAssertEqual(fullHeader, Data("DELETE / \r\nContent-Length: 2"))
		XCTAssertEqual(partialBody, Data("1"))
		XCTAssertEqual(progress, 0.5)
		guard case .finished(let request) = parser.parse(Data("2")) else { return XCTFail("Wrong state") }
		XCTAssertEqual(request.method, .delete)
		XCTAssertEqual(request.path, "/")
		XCTAssertEqual(request.queryParameters, [])
		XCTAssertEqual(request.headers, [.init(name: "Content-Length", value: "2")])
		XCTAssertEqual(request.body, Data("12"))
	}
	
	func test_everythingInFirstEvent() {
		guard case .finished(let request) = parser.parse(Data("HEAD / \r\nContent-Length: 1\r\n\r\n1")) else { return XCTFail("Wrong state") }
		XCTAssertEqual(request.method, .head)
		XCTAssertEqual(request.path, "/")
		XCTAssertEqual(request.queryParameters, [])
		XCTAssertEqual(request.headers, [.init(name: "Content-Length", value: "1")])
		XCTAssertEqual(request.body, Data("1"))
	}
	
	func test_noContentLength_noHeaders() {
		guard case .finished(let request) = parser.parse(Data("HEAD / \r\n\r\n")) else { return XCTFail("Wrong state") }
		XCTAssertEqual(request.method, .head)
		XCTAssertEqual(request.path, "/")
		XCTAssertEqual(request.queryParameters, [])
		XCTAssertEqual(request.headers, [])
		XCTAssertEqual(request.body, Data())
	}
	
	func test_noContentLength_withHeaders() {
		guard case .finished(let request) = parser.parse(Data("HEAD / \r\nHeader: Value\r\n\r\n")) else { return XCTFail("Wrong state") }
		XCTAssertEqual(request.method, .head)
		XCTAssertEqual(request.path, "/")
		XCTAssertEqual(request.queryParameters, [])
		XCTAssertEqual(request.headers, [.init(name: "Header", value: "Value")])
		XCTAssertEqual(request.body, Data())
	}
	
	func test_parsesHeadersWithoutSpace() {
		guard case .finished(let request) = parser.parse(Data("HEAD / \r\nHeader:Value\r\n\r\n")) else { return XCTFail("Wrong state") }
		XCTAssertEqual(request.method, .head)
		XCTAssertEqual(request.path, "/")
		XCTAssertEqual(request.queryParameters, [])
		XCTAssertEqual(request.headers, [.init(name: "Header", value: "Value")])
		XCTAssertEqual(request.body, Data())
	}
	
	func test_noHeadersButExtraLineBreak() {
		guard case .finished(let request) = parser.parse(Data("HEAD / \r\n\r\n\r\n")) else { return XCTFail("Wrong state") }
		XCTAssertEqual(request.method, .head)
		XCTAssertEqual(request.path, "/")
		XCTAssertEqual(request.queryParameters, [])
		XCTAssertEqual(request.headers, [])
		XCTAssertEqual(request.body, Data("\r\n"))
	}
	
	func test_nothingInFirstRequest() {
		guard case .receivingHeader(let partialHeader) = parser.parse(Data()) else { return XCTFail("Wrong state") }
		XCTAssertEqual(partialHeader, Data())
	}
	
	
}

extension Data {
	
	init(_ string: String) {
		self = Data(string.utf8)
	}
	
}
