//
//  Server.swift
//  IntegratedMockTestUITests
//
//  Created by Kane Cheshire on 27/11/2019.
//  Copyright © 2019 kane.codes. All rights reserved.
//

import Foundation

public final class Server {
	
	private var state: State = .notRunning
	private let socket = Socket()
    private var loop: InputLoop?
	private var connections: Set<Connection> = []
	private var configurations: [Configuration] = []
	
	public init() {}
    
    public func start(port: Int = 8881, interface: String = "::1") {
        guard case .notRunning = state else { fatalError("Already started") }
        print("Starting server...", port, interface)
        socket.bind(port: port, interface: interface)
        socket.listen()
        loop = InputLoop(socket: socket) { [weak self] in
            self?.handleIncomingConnection()
        }
        state = .running(port: port, interface: interface)
    }
    
	public func respond(with response: Response, when rules: Rule..., removeAfterResponding: Bool = false) {
		let config = Configuration(response: response, rules: rules, removeAfterResponding: removeAfterResponding)
		configurations.append(config)
	}
	
    public func stop() {
        guard case .running = self.state else { fatalError("Not running") }
        print("Stopping...")
        loop = nil
        connections.removeAll()
        configurations.removeAll()
        // TODO: Unbind port and stop listening?
        self.state = .notRunning
	}
    
    private func handleIncomingConnection() {
        let clientSocket = socket.accept()
        let connection = Connection(client: clientSocket) { [weak self] event, connection in
            self?.handle(event, connection: connection)
        }
        connections.insert(connection)
    }
    
    private func handle(_ request: Request, connection: Connection) {
        let config = configurations.first { config in
            let nonMatchingRule = config.rules.first { $0.verify(request) == false }
            return nonMatchingRule == nil
        }
        if let config = config {
            connection.respond(to: request, with: config.response)
            if config.removeAfterResponding, let index = configurations.firstIndex(of: config) {
                configurations.remove(at: index)
            }
        }
        connections.remove(connection)
    }
	
}

public extension Server {
	
	enum Rule: Hashable {
		
		case method(matches: Request.Method)
		case path(matches: String) // TODO: Handle wildcards
		case headers(contain: Request.Header)
		case queryParameters(contain: Request.QueryParameter)
		case body(matches: Data)
		
		func verify(_ request: Request) -> Bool {
			switch self {
			case .method(matches: let method): return request.method == method
			case .path(matches: let path): return request.path == path
			case .headers(contain: let header): return request.headers.contains(header)
			case .queryParameters(contain: let queryParam): return request.queryParameters.contains(queryParam)
			case .body(matches: let body): return request.body == body
			}
		}
		
	}
	
}

private extension Server {
	
	private enum State {
		case running(port: Int, interface: String)
		case notRunning
	}
	
	private struct Configuration: Hashable {
		let response: Response
		let rules: [Rule]
		let removeAfterResponding: Bool
	}
	
}
