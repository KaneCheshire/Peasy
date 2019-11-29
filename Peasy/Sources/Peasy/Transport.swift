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
	private let loop: Loop
	private let eventHandler: EventHandler
	private var closed = false
	private var closing = false // TODO: Enum for these + open state
	private var outgoingBuffer = Data()
	
	init(socket: Socket, loop: Loop, eventHandler: @escaping EventHandler) {
		// TODO: Ignore sigPipe on tcp?
		self.socket = socket
		self.loop = loop
		self.eventHandler = eventHandler
		loop.setReader(socket.tag) { [weak self] in
			self?.handleRead()
		}
	}
	
	func close() {
		print("Closing transport...")
		guard !closed else { return }
		guard !closing else { return }
		closing = true
		closedByPeer()
	}
	
	func write(_ data: Data) {
		guard !closed else { return }
		guard !closing else { return }
		outgoingBuffer.append(data)
		handleWrite()
	}
	
	private func handleRead() {
		guard !closed else { return }
		guard !closing else { return }
		// TODO: Check if reading
		switch socket.receive(size: 1024)  { // TODO: 1024 Repeated a bit
		case .success(let data):
			guard !data.isEmpty else { return closedByPeer() } // TODO: Is this needed?
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
	
	private func closedByPeer() {
		loop.removeReader(socket.tag)
		loop.removeWriter(socket.tag)
		socket.cleanup()
		closed = true
		eventHandler(.closed)
	}
	
	private func handleWrite() {
		guard !closed else { return }
		guard !outgoingBuffer.isEmpty else {
			if closing {
				loop.removeReader(socket.tag)
				loop.removeWriter(socket.tag)
				socket.cleanup()
				eventHandler(.closed)
				closed = true
			}
			return
		}
		switch socket.send(outgoingBuffer) {
		case .success(let bytesSent):
			outgoingBuffer.removeFirst(bytesSent)
			if !outgoingBuffer.isEmpty {
				print("Buffer is not empty, assigning write handler")
				loop.setWriter(socket.tag) { [weak self] in self?.handleWrite() }
			} else {
				print("Buffer is empty, removing writer")
				loop.removeWriter(socket.tag)
				if closing {
					print("Closing...")
					loop.removeReader(socket.tag)
					socket.cleanup()
					eventHandler(.closed) // TODO: This code is repeated sort of
					closed = true
				}
			}
		case .failure(.number(let number)):
			switch number {
			case EAGAIN: break
			case EPROTOTYPE, EPIPE: closedByPeer()
			default: fatalError()
			}
		}
	}
	
}
