import XCTest
@testable import Peasy

final class Array_firstPathTests: XCTestCase {
	
	func test_noPaths() {
		let rules: [Server.Rule] = [.body(matches: Data())]
		XCTAssertNil(rules.firstPath)
	}
	
	func test_multiplePaths() {
		let rules: [Server.Rule] = [.body(matches: Data()), .path(matches: "a"), .path(matches: "b")]
		XCTAssertEqual(rules.firstPath, "a")
	}
	
}
