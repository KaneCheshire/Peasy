//
//  Connection.swift
//  Peasy
//
//  Created by Kane Cheshire on 28/11/2019.
//  Copyright © 2019 kane.codes. All rights reserved.
//

import Foundation

final class Connection {
	
	enum Event {
		case requestReceived(Request)
		case finished
	}
	
	typealias EventHandler = (Event, Connection) -> Void
	
	private let uuid = UUID()
	private let handler: EventHandler
	private let client: Socket
	private var parser = RequestParser()
	private let eventListener: EventListener
	
	init(client: Socket, eventListener: EventListener, handler: @escaping EventHandler) {
		self.client = client
		self.handler = handler
		self.eventListener = eventListener
		eventListener.register(client) { [weak self] in
			self?.handleDataAvailable()
		}
	}
	
	deinit {
		eventListener.unregister(client)
		client.close()
	}
	
	func respond(with response: Response) {
		switch client.write(response.httpRep) {
			case .success: break
			case .failure(let error): fatalError(error.message)
		}
	}
	
	private func handleDataAvailable() {
		switch client.read() {
			case .success(let data): handle(data)
			case .failure(let error): fatalError(error.message)
		}
	}
	
	private func handle(_ data: Data) {
		if data.isEmpty {
			handler(.finished, self)
		} else {
			parse(data)
		}
	}
	
	private func parse(_ data: Data) {
		switch parser.parse(data) {
			case .finished(let request):
				handler(.requestReceived(request), self)
				handler(.finished, self)
			case .notStarted, .receivingHeader, .receivingBody: break
		}
	}
	
}

extension Connection: Hashable {
	
	static func == (lhs: Connection, rhs: Connection) -> Bool {
		return lhs.uuid == rhs.uuid
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(uuid)
	}
	
}
