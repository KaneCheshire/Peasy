//
//  Server.swift
//  Peasy
//
//  Created by Kane Cheshire on 27/11/2019.
//  Copyright © 2019 kane.codes. All rights reserved.
//

import Foundation
import CryptoKit

public let anyAvailablePort: Int = 0

/// This is the Peasy server.
/// Create a server and then call  `start`.
/// It's that easy. Easy peasy!
public final class Server {
    
    public typealias ConfigurationToken = UUID
    
    public var isRunning: Bool {
        switch state {
        case .notRunning: return false
        case .running: return true
        }
    }
	
	// MARK: - Properties -
	// MARK: Private
	
	private var state: State = .notRunning
	private var connections: Set<HTTPConnection> = []
    private var webSocketConnections: Set<WebSocketConnection> = []
	private var configurations: [Configuration] = []
	
	// MARK: - Init -
	// MARK: Public
	
	public init() {}
	
	// MARK: - Functions -
	// MARK: Public
	
	/// Starts the server on the specified port (or the default port if no port is specified)
	///
	/// It is an error to attempt to start more than one server on the same port without calling `stop`  on the previous server first.
	/// - Parameter port: The port that should be used to bind the server to. Specify port `0` to let the operating system choose an available port for you.
	/// - Returns: Port the server listens on
	@discardableResult
    public func start(port: Int = anyAvailablePort, queue: DispatchQueue = .shared) -> Int {
		switch state {
        case .notRunning: return createSocket(bindingTo: port, queue: queue)
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
	///   - delay: If provided, the response will be delayed by the specified delay when the rules are matched.
	///   - removeAfterResponding: Whether the configuration should be removed after the response has been made. This is useful for replying with different responses when a request is made more than once. Defaults to false.
    @discardableResult
	public func respond(with response: Response, when rules: Rule..., delay: TimeInterval? = nil, removeAfterResponding: Bool = false) -> ConfigurationToken {
        respond(with: .http { _ in response }, when: rules, removeAfterResponding: removeAfterResponding, delay: delay)
	}
	
	/// Configures the server to respond to requests that match the provided rules.
	///
	/// You must configure the server to know what to respond to requests before requests are made, otherwise
	/// the connection will be closed with no response.
	///
	/// - Parameters:
	///   - response: A handler that is performed for you to take some action on request before providing a response.
	///   - rules: The rules to match the request with. You can provide multiple rules using commas.
	///   - delay: If provided, the response will be delayed by the specified delay when the rules are matched.
	///   - removeAfterResponding: Whether the configuration should be removed after the response has been made. This is useful for replying with different responses when a request is made more than once. Defaults to false.
    @discardableResult
	public func respond(with response: @escaping () -> Response, when rules: Rule..., delay: TimeInterval? = nil, removeAfterResponding: Bool = false) -> ConfigurationToken {
        respond(with: .http { _ in response() }, when: rules, removeAfterResponding: removeAfterResponding, delay: delay)
	}
	
	/// Configures the server to respond to requests that match the provided rules.
	///
	/// You must configure the server to know what to respond to requests before requests are made, otherwise
	/// the connection will be closed with no response.
	///
	/// - Parameters:
	///   - response: A handler that is performed for you to take some action on request before providing a response. The Request is provided to you to inspect as part of this handler.
	///   - rules: The rules to match the request with. You can provide multiple rules using commas.
	///   - delay: If provided, the response will be delayed by the specified delay when the rules are matched.
	///   - removeAfterResponding: Whether the configuration should be removed after the response has been made. This is useful for replying with different responses when a request is made more than once. Defaults to false.
    @discardableResult
	public func respond(with response: @escaping (Request) -> Response, when rules: Rule..., delay: TimeInterval? = nil, removeAfterResponding: Bool = false) -> ConfigurationToken {
        respond(with: .http(response), when: rules, removeAfterResponding: removeAfterResponding, delay: delay)
	}
    
    @discardableResult
    public func respond(with response: WebSocketResponse, when rules: Rule..., delay: TimeInterval? = nil, removeAfterResponding: Bool = false) -> ConfigurationToken {
        respond(with: .webSocket { _ in response }, when: rules, removeAfterResponding: removeAfterResponding, delay: delay)
    }
    
    @discardableResult
    public func respond(with response: @escaping () -> WebSocketResponse, when rules: Rule..., delay: TimeInterval? = nil, removeAfterResponding: Bool = false) -> ConfigurationToken {
        respond(with: .webSocket { _ in response() }, when: rules, removeAfterResponding: removeAfterResponding, delay: delay)
    }
    
    @discardableResult
    public func respond(with response: @escaping (Request) -> WebSocketResponse, when rules: Rule..., delay: TimeInterval? = nil, removeAfterResponding: Bool = false) -> ConfigurationToken {
        respond(with: .webSocket(response), when: rules, removeAfterResponding: removeAfterResponding, delay: delay)
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
    
    public func remove(configuration: ConfigurationToken) {
        guard let index = self.configurations.firstIndex(where: { $0.uuid == configuration }) else { return }
        self.configurations.remove(at: index)
    }
	
	// MARK: Private
	
    private func createSocket(bindingTo port: Int, queue: DispatchQueue) -> Int {
		let socket = Socket()
		let port = socket.bind(port: port)
		let eventListener = EventListener()
		eventListener.register(socket) { [weak self] in
			self?.handleIncomingConnection()
		}
		eventListener.start(queue: queue)
		state = .running(socket, eventListener)
		print("Started server on port", port)
		return port
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
        let connection = HTTPConnection(
            client: clientSocket,
            eventListener: eventListener)
        { [weak self] request, connection in
            self?.handle(request, for: connection)
        }
        connections.insert(connection)
	}
	
    private func handle(_ request: Request?, for connection: HTTPConnection) {
        if let request {
            handle(request, for: connection)
        } else {
            connections.remove(connection)
        }
	}
	
    private func handle(_ request: Request, for connection: HTTPConnection) {
        guard let config = configurations[request] else {
            return print("Unable to find configuration for request so unable to respond: \(request)")
        }
        var request = request
        request.updateVariables(from: config.rules)
        let handler: () -> Void = { [weak self] in
            self?.respond(to: request, for: connection, with: config)
        }
        if let interval = config.delay {
            DispatchQueue.shared.asyncAfter(deadline: .now() + interval, execute: handler)
        } else {
            handler()
        }
	}
	
    private func respond(to request: Request, for connection: HTTPConnection, with config: Configuration) {
        let sendRegularHTTPResponse = { (response: Response) in
            connection.send(response)
            connection.close()
            self.connections.remove(connection) // TODO: Leak?
        }
        switch config.responseType {
        case let .http(response):
            sendRegularHTTPResponse(response(request))
        case let .webSocket(webSocketResponse):
            switch webSocketResponse(request) {
            case let .reject(response):
                sendRegularHTTPResponse(response)
            case let .allow(webSocket):
                if #available(iOS 13.0, macOS 10.15, *) { // TODO
                    connection.send(.upgradeWebSocket(upgradeRequest: request))
                    let webSocketConnection = connection.upgradeToWebSocket { frame, connection in
                        webSocket.onFrameReceived(webSocket, frame)
                    }
                    webSocket.onSendFrame = { [weak webSocketConnection] frame in
                        webSocketConnection?.send(frame)
                    }
                    webSocket.onClose = { [weak webSocketConnection, weak self] info in
                        guard let connection = webSocketConnection else { return assertionFailure() }
                        self?.close(webSocketConnection: connection, with: info)
                    }
                    connections.remove(connection)
                    webSocketConnections.insert(webSocketConnection)
                }
            }
        }
        handle(used: config)
	}
    
    private func close(webSocketConnection: WebSocketConnection, with info: Frame.ClosedInfo?) {
        webSocketConnection.close(with: info)
        webSocketConnections.remove(webSocketConnection)
    }
	
	private func handle(used config: Configuration) {
		guard config.removeAfterResponding, let index = configurations.lastIndex(of: config) else { return }
		configurations.remove(at: index)
	}
	
    private func respond(with responseType: Configuration.ResponseType, when rules: [Rule], removeAfterResponding: Bool, delay: TimeInterval?) -> ConfigurationToken {
        let config = Configuration(responseType: responseType, rules: rules, removeAfterResponding: removeAfterResponding, delay: delay)
		configurations.append(config)
        return config.uuid
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
    
    final class WebSocketProxy {
        
        let onFrameReceived: (WebSocketProxy, Frame) -> Void
        var onClose: ((Frame.ClosedInfo?) -> Void)?
        var onSendFrame: ((Frame) -> Void)?
        
        public init(onFrameReceived: @escaping (WebSocketProxy, Frame) -> Void) {
            self.onFrameReceived = onFrameReceived
        }
        
        public func close(info: Frame.ClosedInfo?) {
            onClose?(info)
        }
        
        public func send(frame: Frame) {
            onSendFrame?(frame)
        }
    }
    
    enum WebSocketResponse {
        case allow(webSocket: WebSocketProxy)
        case reject(with: Response)
    }
}

extension Server {
	
	enum State {
		case running(Socket, EventListener)
		case notRunning
	}
	
	struct Configuration {
        
        enum ResponseType {
            case http((Request) -> Response)
            case webSocket((Request) -> WebSocketResponse)
        }
        
		let uuid = UUID()
        let responseType: ResponseType
		let rules: [Rule]
		let removeAfterResponding: Bool
		let delay: TimeInterval?
	}
}

extension Server.Configuration: Equatable {

	static func == (lhs: Server.Configuration, rhs: Server.Configuration) -> Bool {
		return lhs.uuid == rhs.uuid
	}

}

public extension Request {
    
    var isWebSocket: Bool {
        self[header: "Upgrade"] == "websocket" // TODO :subscript on headers array instead?
    }
}
