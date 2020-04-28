//
//  EventListener.swift
//  
//
//  Created by Kane Cheshire on 30/11/2019.
//

import Foundation

final class EventListener {
	
	private let queue = kqueue()
	private var handlers: [Int32: () -> Void] = [:]
	private var item = DispatchWorkItem {}
	
	func stop() {
		item.cancel()
		handlers.forEach { tag in
			setState(EV_DELETE, socket: tag.key)
		}
	}
	
	func start() {
		item = DispatchWorkItem { [weak self] in
			self?.performCheck()
		}
		DispatchQueue.shared.async(execute: item)
	}
	
	func register(_ socket: Socket, _ handler: @escaping () -> Void) {
		handlers[socket.tag] = handler
		setState(EV_ADD, socket: socket.tag)
	}
	
	func unregister(_ socket: Socket) {
		setState(EV_DELETE, socket: socket.tag)
		handlers[socket.tag] = nil
	}
	
	private func performCheck() {
		events().forEach { e in
			handlers[e]!()
		}
		start()
	}
	
	private func setState(_ state: Int32, socket: Int32) {
		var events = [kevent(ident: UInt(socket), filter: Int16(EVFILT_READ), flags: UInt16(state), fflags: 0, data: 0, udata: nil)]
		let eventCount = events.count
		let success = events.withUnsafeMutableBufferPointer { kevent(queue, $0.baseAddress, Int32(eventCount), nil, 0, nil) >= 0 }
		guard success else { fatalError(DarwinError().message) }
	}
	
	private func events() -> [Int32] {
		var timeout = timespec()
		var events = Array<kevent>(repeating: kevent(), count: 1024)
		let success = events.withUnsafeMutableBufferPointer { kevent(queue, nil, 0, $0.baseAddress, 1024, &timeout) >= 0 }
		guard success else { fatalError(DarwinError().message) }
		return events.compactMap { event in
			guard event.filter == EVFILT_READ else { return nil }
			return Int32(event.ident)
		}
	}
	
}
