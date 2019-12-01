//
//  Server.swift
//  Peasy
//
//  Created by Kane Cheshire on 27/11/2019.
//  Copyright © 2019 kane.codes. All rights reserved.
//

import Foundation

public final class Server {
	
	private var state: State = .notRunning
	private var connections: Set<Connection> = []
	private var configurations: [Configuration] = []
	
	public init() {}
	
	public func start(port: Int = 8881) {
		switch state {
			case .notRunning:
				let socket = Socket()
				socket.bind(port: port)
				let eventListener = EventListener(socket: socket) { [weak self] in self?.handleIncomingConnection() }
				state = .running(socket, eventListener)
				print("Started server on port", port)
			case .running: fatalError("Cannot start server because it's already started.")
		}
	}
	
	public func respond(with response: Response, when rules: Rule..., removeAfterResponding: Bool = false) {
		let config = Configuration(response: response, rules: rules, removeAfterResponding: removeAfterResponding)
		configurations.append(config)
	}
	
	public func stop() {
		switch state {
			case .running(let socket, let eventListener):
				print("Stopping...")
				eventListener.close()
				socket.close()
				connections.removeAll()
				configurations.removeAll()
				state = .notRunning
			case .notRunning: fatalError("Cannot stop server because it's not running.")
		}
	}
	
	private func handleIncomingConnection() {
		switch state {
			case .running(let socket, _): acceptClientSocket(from: socket)
			case .notRunning: break
		}
	}
	
	private func acceptClientSocket(from socket: Socket) {
		let clientSocket = socket.accept()
		let connection = Connection(client: clientSocket) { [weak self] event, connection in
			self?.handle(event, for: connection)
		}
		connections.insert(connection)
	}
	
	private func handle(_ event: Connection.Event, for connection: Connection) {
		switch event {
			case .requestReceived(let request): handle(request, for: connection)
			case .finished: connections.remove(connection)
		}
	}
	
	private func handle(_ request: Request, for connection: Connection) {
		guard let config = configurations.matching(request) else { return }
		connection.respond(to: request, with: config.response)
		handle(used: config)
	}
	
	private func handle(used config: Configuration) {
		guard config.removeAfterResponding, let index = configurations.firstIndex(of: config) else { return }
		configurations.remove(at: index)
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
	
	enum State {
		case running(Socket, EventListener)
		case notRunning
	}
	
	struct Configuration: Hashable {
		let response: Response
		let rules: [Rule]
		let removeAfterResponding: Bool
	}
	
}

private extension Array where Element == Server.Configuration {
	
	func matching(_ request: Request) -> Element? {
		return first { config in
			let nonMatchingRule = config.rules.first { $0.verify(request) == false }
			return nonMatchingRule == nil
		}
	}
	
}
