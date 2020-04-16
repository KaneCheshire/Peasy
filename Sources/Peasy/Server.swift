//
//  Server.swift
//  Peasy
//
//  Created by Kane Cheshire on 27/11/2019.
//  Copyright © 2019 kane.codes. All rights reserved.
//

import Foundation

/// This is the Peasy server.
/// Create a server and then call  `start`.
/// It's that easy. Easy peasy!
public final class Server {
	
	// MARK: - Properties -
	// MARK: Private
	
	private var state: State = .notRunning
	private var connections: Set<Connection> = []
	private var configurations: [Configuration] = []
	
	// MARK: - Init -
	// MARK: Public
	
	public init() {}
	
	// MARK: - Functions -
	// MARK: Public
	
	/// Starts the server on the specified port (or the default port if no port is specified)
	///
	/// It is an error to attempt to start more than one server on the same port without calling `stop`  on the previous servers first.
	public func start(port: Int = 8880) {
		switch state {
			case .notRunning: createSocket(bindingTo: port)
			case .running: fatalError("Cannot start server because it's already started.")
		}
	}
	
	/// Configures the server to respond to requests that match the provided rules.
	///
	/// You must configure the server to know what to respond to requests before requests are made, otherwise
	/// the connection will be closed with no response.
	///
	/// - Parameters:
	///   - response: The response to respond to the matching request with.
	///   - rules: The rules to match the request with. You can provide multiple rules using commas.
	///   - removeAfterResponding: Whether the configuration should be removed after the response has been made. This is useful for replying with different responses when a request is made more than once. Defaults to false.
	public func respond(with response: Response, when rules: Rule..., removeAfterResponding: Bool = false) {
		respond(with: { _ in response }, when: rules, removeAfterResponding: removeAfterResponding)
	}
	
	/// Configures the server to respond to requests that match the provided rules.
	///
	/// You must configure the server to know what to respond to requests before requests are made, otherwise
	/// the connection will be closed with no response.
	///
	/// - Parameters:
	///   - response: A handler that is performed for you to take some action on request before providing a response.
	///   - rules: The rules to match the request with. You can provide multiple rules using commas.
	///   - removeAfterResponding: Whether the configuration should be removed after the response has been made. This is useful for replying with different responses when a request is made more than once. Defaults to false.
	public func respond(with response: @escaping () -> Response, when rules: Rule..., removeAfterResponding: Bool = false) {
		respond(with: { _ in response() }, when: rules, removeAfterResponding: removeAfterResponding)
	}
	
	/// Configures the server to respond to requests that match the provided rules.
	///
	/// You must configure the server to know what to respond to requests before requests are made, otherwise
	/// the connection will be closed with no response.
	///
	/// - Parameters:
	///   - response: A handler that is performed for you to take some action on request before providing a response. The Request is provided to you to inspect as part of this handler.
	///   - rules: The rules to match the request with. You can provide multiple rules using commas.
	///   - removeAfterResponding: Whether the configuration should be removed after the response has been made. This is useful for replying with different responses when a request is made more than once. Defaults to false.
	public func respond(with response: @escaping (Request) -> Response, when rules: Rule..., removeAfterResponding: Bool = false) {
		respond(with: response, when: rules, removeAfterResponding: removeAfterResponding)
	}
	
	/// Stops the server and frees up the port used when calling `start`.
	public func stop() {
		switch state {
			case .running(let socket, let eventListener):
				eventListener.stop()
				socket.close()
				connections.removeAll()
				configurations.removeAll()
				state = .notRunning
			case .notRunning: fatalError("Cannot stop server because it's not running.")
		}
	}
	
	// MARK: Private
	
	private func createSocket(bindingTo port: Int) {
		let socket = Socket()
		socket.bind(port: port)
		let eventListener = EventListener()
		eventListener.register(socket) { [weak self] in
			self?.handleIncomingConnection()
		}
		eventListener.start()
		state = .running(socket, eventListener)
		print("Started server on port", port)
	}
	
	private func handleIncomingConnection() {
		switch state {
			case .running(let socket, let eventListener):
				acceptClientSocket(from: socket, eventListener: eventListener)
			case .notRunning: break
		}
	}
	
	private func acceptClientSocket(from socket: Socket, eventListener: EventListener) {
		let clientSocket = socket.accept()
		let connection = Connection(client: clientSocket, eventListener: eventListener) { [weak self] event, connection in
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
        guard let config = configurations[request] else { return }
		var request = request
		request.updateVariables(from: config.rules)
        let response = config.response(request)
		connection.respond(with: response)
		handle(used: config)
	}
	
	private func handle(used config: Configuration) {
		guard config.removeAfterResponding, let index = configurations.lastIndex(of: config) else { return }
		configurations.remove(at: index)
	}
	
	private func respond(with response: @escaping (Request) -> Response, when rules: [Rule], removeAfterResponding: Bool) {
		let config = Configuration(response: response, rules: rules, removeAfterResponding: removeAfterResponding)
		configurations.append(config)
	}
	
}

public extension Server {
	
	/// Represents a rule to match requests with.
	enum Rule {
		case method(matches: Request.Method)
		case path(matches: String)
		case headers(contain: Request.Header)
		case queryParameters(contain: Request.QueryParameter)
		case body(matches: Data)
		case custom((Request) -> Bool)
	}
	
}

extension Server {
	
	enum State {
		case running(Socket, EventListener)
		case notRunning
	}
	
	struct Configuration {
		let uuid = UUID()
		let response: (Request) -> Response
		let rules: [Rule]
		let removeAfterResponding: Bool
	}
	
}

extension Server.Configuration: Equatable {
	
	static func == (lhs: Server.Configuration, rhs: Server.Configuration) -> Bool {
		return lhs.uuid == rhs.uuid
	}
	
}
