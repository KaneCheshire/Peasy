//
//  Connection.swift
//  IntegratedMockTestUITests
//
//  Created by Kane Cheshire on 28/11/2019.
//  Copyright © 2019 kane.codes. All rights reserved.
//

import Foundation
import UIKit

class Connection {
	
	typealias EventHandler = (Event, Connection) -> Void
	
	enum Event {
		case requestReceived(Request)
		case closed
	}
	
	private let uuid = UUID()
	private let handler: EventHandler
	private var transport: Transport! // TODO: Not ideal
	private var parser = RequestParser()
	
	init(client: Socket, handler: @escaping EventHandler) {
		self.handler = handler
		self.transport = Transport(socket: client) { [weak self] event in
			switch event {
			case .dataReceived(let data):
				self?.handle(data)
			case .closed:
				guard let self = self else { return }
				handler(.closed, self)
			}
		}
	}
	
	func respond(to request: Request, with data: Data, completion: @escaping () -> Void) {
		transport.write(data)
		close()
		completion()
	}
	
	func close() {
		transport.close()
	}
	
	private func handle(_ data: Data) {
		switch parser.parse(data) {
		case .finished(let request):
			handler(.requestReceived(request), self)
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
