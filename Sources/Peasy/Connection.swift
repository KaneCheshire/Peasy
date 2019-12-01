//
//  Connection.swift
//  IntegratedMockTestUITests
//
//  Created by Kane Cheshire on 28/11/2019.
//  Copyright © 2019 kane.codes. All rights reserved.
//

import Foundation
import UIKit

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
	private var inputLoop: InputLoop?
	
	init(client: Socket, handler: @escaping EventHandler) {
		self.client = client
		self.handler = handler
		inputLoop = InputLoop(socket: client) { [weak self] in // TODO: Not convinced this loop is even needed now
			self?.handleDataAvailable()
		}
	}
	
	func respond(to request: Request, with response: Response) {
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
			switch parser.parse(data) {
				case .finished(let request):
					handler(.requestReceived(request), self)
					handler(.finished, self)
				case .notStarted, .receivingHeader, .receivingBody: break
			}
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
