//
//  Transport.swift
//  IntegratedMockTestUITests
//
//  Created by Kane Cheshire on 28/11/2019.
//  Copyright © 2019 kane.codes. All rights reserved.
//

import Foundation

class Transport {
	
	typealias EventHandler = (Event) -> Void
	
	enum Event {
		case dataReceived(Data)
		case closed
	}
	
	private let socket: Socket
	private let eventHandler: EventHandler
	private var closed = false // TODO: Enum for these + open state
    private var inputLoop: InputLoop?
	
	init(socket: Socket, eventHandler: @escaping EventHandler) {
		self.socket = socket
		self.eventHandler = eventHandler
        inputLoop = InputLoop(socket: socket) { [weak self] in
            self?.handleRead()
        }
	}
	
	func close() {
        guard !closed else { return }
        print("Closing transport...")
		socket.cleanup()
        closed = true
        eventHandler(.closed)
	}
	
	func write(_ data: Data) {
		guard !closed else { return }
		switch socket.send(data) {
        case .success(let bytesSent):
            guard data.count == bytesSent else { fatalError() }
            print("Buffer is empty, removing writer")
            close()
        case .failure(.number(let number)):
            switch number {
            case EAGAIN: fatalError()
            case EPROTOTYPE, EPIPE: close()
            default: fatalError()
            }
        }
	}
	
	private func handleRead() {
		guard !closed else { return }
		switch socket.receive(size: 1024)  { // TODO: 1024 Repeated a bit
		case .success(let data):
			eventHandler(.dataReceived(data))
        case .failure(let error):
			switch error {
			case .number(let number):
				switch number {
				case EAGAIN: break
				default: fatalError()
				}
			}
		}
	}
	
}
