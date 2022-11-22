import XCTest
import System
@testable import Peasy

extension URLSession {
    
    static var test: URLSession {
        // This forces task callbacks to be on the main queue to speed up tests
        URLSession(configuration: .default, delegate: nil, delegateQueue: .main)
    }
}

@available(macOS 12.0, *)
final class WebSocket: NSObject, URLSessionWebSocketDelegate {
    
    private let session: URLSession
    private let task: URLSessionWebSocketTask
    private var onOpen: (() -> Void)?
    private var onClose: ((URLSessionWebSocketTask.CloseCode, Data?) -> Void)?
    
    init(
        session: URLSession = .test,
        url: URL
    ) {
        self.session = session
        task = session.webSocketTask(with: url)
        super.init()
        task.delegate = self
    }
    
    func open() {
        task.resume()
    }
    
    func cancel() {
        task.cancel(with: .goingAway, reason: nil)
    }
    
    func onOpen(_ handler: @escaping () -> Void) {
        self.onOpen = handler
    }
    
    func onClose(_ handler: @escaping (URLSessionWebSocketTask.CloseCode, Data?) -> Void) {
        self.onClose = handler
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        onOpen?()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        onClose?(closeCode, reason)
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print(">>>>>>", error?.localizedDescription ?? "")
    }
}

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
    
    func test_ping() throws {
        let server = Server()
        let proxy = Server.WebSocketProxy { proxy, frame in
//            XCTAssertEqual(frame, .ping)
            // TODO: Make this easier (specifics around response needing same payload
//            let pong = Frame(final: true, opCode: .pong, payload: frame.payload)
//            proxy.send(frame: pong)
        }
        server.respond(with: .allow(webSocket: proxy), when: .path(matches: "/"))
        let port = server.start(queue: .main)
        let url = URL(string: "ws://localhost:\(port)")!
        let task = URLSession.test.webSocketTask(with: url)
        task.resume()
        let exp = self.expectation(description: "")
        task.sendPing { error in
            XCTAssertNil(error, error!.localizedDescription)
            exp.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    @available(macOS 12.0, *)
    func test_close_server() throws {
        let server = Server()
        let proxy = Server.WebSocketProxy { proxy, frame in }
        server.respond(with: .allow(webSocket: proxy), when: .path(matches: "/"))
        let port = server.start(queue: .main)
        let url = URL(string: "ws://localhost:\(port)")!
        let task = WebSocket(url: url)
        let exp = self.expectation(description: "")
        task.onOpen {
            proxy.close(info: .init(code: 1005, reason: nil))
//            task.cancel()
        }
        task.onClose { c, r in
            exp.fulfill()
        }
        task.open()
        
        
//        task.send(.data(Data())) { error in
//            XCTAssertNil(error)
//            XCTAssertEqual(task.closeCode, .invalid)
//            proxy.close()
//
//            func check() {
//                if task.closeCode != .normalClosure {
//                    DispatchQueue.main.async {
//                        check()
//                    }
//                } else {
//                    exp.fulfill()
//                }
//            }
//        }
//        task.receive { res in
//            switch res {
//            case .success:
//                XCTFail()
//            case .failure(let error as NSError):
//                let errNo = Errno(rawValue: CInt(error.code))
//                XCTAssertEqual(errNo, .socketNotConnected)
//                XCTAssertEqual(task.closeCode, .noStatusReceived)
//                XCTAssertEqual(task.closeReason, Data())
//                exp.fulfill()
//            }
//        }
//        proxy.close()
        waitForExpectations(timeout: 10)
    }
    
    func test() throws {
        let server = Server()
        let port = server.start()
        let proxy = Server.WebSocketProxy { proxy, frame in
            switch frame {
            case .binary(let data):
                print("")
            default: break
            }
        }
        server.respond(with: .allow(webSocket: proxy), when: .custom { _ in true })
        let url = URL(string: "ws://localhost:\(port)")!
        let task = URLSession.shared.webSocketTask(with: url)
        task.resume()
        let expectation = self.expectation(description: "")
        task.receive { result in
            print(result)
            expectation.fulfill()
        }
        task.send(.data(Data("!hello hello $".utf8))) { error in
            XCTAssertNil(error)
            print("done")
        }
//        let message = try await task.receive()
//        print(message)
//        task.cancel(with: .normalClosure, reason: nil)
        self.waitForExpectations(timeout: 100)
    }
}

