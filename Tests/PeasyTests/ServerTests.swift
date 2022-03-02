import XCTest
@testable import Peasy

final class ServerTests: XCTestCase {

	func testChoosesAvailableByDefault() {
		let serverA = Server()
		let serverB = Server()
		defer {
			serverA.stop()
			serverB.stop()
		}
		let portA = serverA.start()
		let portB = serverB.start()
		
		XCTAssertNotEqual(portA, portB)
	}
	
	
    func testBindPort() throws {
        let server = Server()
        let port = 8880
        let usedPort = server.start(port: port)
        defer { server.stop() }
        
        XCTAssertEqual(port, usedPort)
    }

    func testSystemChosenPort() throws {
        let server = Server()
        let usedPort = server.start(port: 0)
        defer { server.stop() }
        
        XCTAssert(usedPort > 0)
    }
	
	func testRangeOfPorts() throws {
		let server1 = Server()
		let server2 = Server()
		let port1 = server1.start(ports: 8080..<8090)
		let port2 = server2.start(ports: 8080..<8090)
		
		defer { server1.stop() }
		defer { server2.stop() }
		
		XCTAssertEqual(port1, 8080)
		XCTAssertEqual(port2, 8081)
	}

    func testConnectionOnSpecifiedPort() throws {
        let server = Server()
        
        let port = 8880
        server.start(port: port)
        server.respond(with: Response(status: .ok))
        
        let address = URL(string: "http://localhost:\(port)")!
        
        let expectation = self.expectation(description: "Completion")
        let dataTask = URLSession.shared.dataTask(with: address) { (data, response, error) in
            XCTAssertNil(error)
            XCTAssertEqual((response as! HTTPURLResponse).statusCode, 200)
            expectation.fulfill()
            server.stop()
        }
        dataTask.resume()
        
        wait(for: [expectation], timeout: 5.0)
    }

    func testConnectionOnSystemChosenPort() throws {
        let server = Server()
        
        let port = server.start(port: 0)
        server.respond(with: Response(status: .ok))
        
        let address = URL(string: "http://localhost:\(port)")!
        
        let expectation = self.expectation(description: "Completion")
        let dataTask = URLSession.shared.dataTask(with: address) { (data, response, error) in
            XCTAssertNil(error)
            XCTAssertEqual((response as! HTTPURLResponse).statusCode, 200)
            expectation.fulfill()
            server.stop()
        }
        dataTask.resume()
        
        wait(for: [expectation], timeout: 5.0)
    }
	
	func testConnectionOnRangeOfPorts() throws {
		let servers = [Server(), Server(), Server()]
		
		let expectations: [XCTestExpectation] = try servers.map { server in
			let port = server.start(ports: 8080..<8090)
			server.respond(with: Response(status: .ok))
			let address = try XCTUnwrap(URL(string: "http://localhost:\(port)"))
			
			let expectation = self.expectation(description: "Completion")
			let dataTask = URLSession.shared.dataTask(with: address) { (data, response, error) in
				XCTAssertNil(error)
				XCTAssertEqual((response as! HTTPURLResponse).statusCode, 200)
				expectation.fulfill()
				server.stop()
			}
			dataTask.resume()
			return expectation
		}
		
		wait(for: expectations, timeout: 5.0)
	}
}
