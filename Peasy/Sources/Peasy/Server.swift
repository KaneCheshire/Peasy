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
	private let loop = Loop()
	private var connections: Set<Connection> = []
    private var configurations: [Configuration] = []
	
    public init() {}
    
	public func start(port: Int = 8881, interface: String = "::1") {
        DispatchQueue.global(qos: .background).async {
            guard case .notRunning = self.state else { fatalError("Already started") }
            print("Starting server...", port, interface)
            self.socket.bind(port: port, interface: interface)
            self.socket.listen()
            self.loop.setReader(self.socket.tag) { [weak self] in
                self?.handleIncomingConnection(port: port, interface: interface)
            }
            self.loop.run()
            self.state = .running(port: port, interface: interface)
        }
	}
    
    public func respond(with response: Response, when rules: Rule..., removeAfterResponding: Bool = false) {
        let config = Configuration(response: response, rules: rules, removeAfterResponding: removeAfterResponding)
        configurations.append(config)
    }
    
    public func stop() {
        DispatchQueue.global(qos: .background).async {
            guard case .running = self.state else { fatalError("Not running") }
            print("Stopping...")
            self.loop.removeReader(self.socket.tag)
            self.loop.stop()
            // TODO: Unbind port and stop listening?
            self.state = .notRunning
        }
    }
	
}

public extension Server {
    
    enum Rule: Hashable {
        
        case method(matches: Request.Method)
        case path(matches: String) // TODO: Handle wildcards
        case contains(header: Request.Header) // TODO: Handle only responding after a number of requests, or changing the response after a number of requests
        case body(matches: Data) // TOOD: Handle queries
        
        func verify(_ request: Request) -> Bool {
            switch self {
                case .method(matches: let method): return request.method == method
                case .path(matches: let path): return request.path == path
                case .contains(header: let header): return request.headers.contains(header)
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
    
    private func handleIncomingConnection(port: Int, interface: String) {
        let clientSocket = socket.accept()
        let connection = Connection(client: clientSocket, loop: loop) { [weak self] event, connection in
            self?.handle(event, connection: connection)
        }
        connections.insert(connection)
    }
    
    private func handle(_ event: Connection.Event, connection: Connection) {
        switch event {
        case .requestReceived(let request):
            let config = configurations.first { config in
                let nonMatchingRule = config.rules.first { $0.verify(request) == false }
                return nonMatchingRule == nil
            }
            if let response = config?.response {
                connection.respond(to: request, with: Data(response.httpRep.utf8)) { [weak self] in
                    if let config = config, config.removeAfterResponding, let index = self?.configurations.firstIndex(of: config) {
                        self?.configurations.remove(at: index)
                    }
                }
            } else {
                connection.close()
            }
        case .closed:
            connections.remove(connection)
        }
    }
    
}
