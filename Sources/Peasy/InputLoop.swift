//
//  InputLoop.swift
//  
//
//  Created by Kane Cheshire on 30/11/2019.
//

import Foundation

final class InputLoop {
    
    private let socket: Socket
    private let handler: () -> Void
    private let queue = kqueue()
    private let dispatchQueue = DispatchQueue(label: "codes.kane.Peasy.IncomingConnections", qos: .background)
    
    init(socket: Socket, _ handler: @escaping () -> Void) {
        self.socket = socket
        self.handler = handler
        setState(EV_ADD)
        tick()
    }
    
    deinit { setState(EV_DELETE) }
    
    private func tick() {
        dispatchQueue.async { [weak self] in self?.tock() }
    }
    
    private func tock() {
        defer { tick() }
        events().forEach { _ in handler() }
    }
    
    private func setState(_ state: Int32) {
        var events = [Darwin.kevent(ident: UInt(socket.tag), filter: Int16(EVFILT_READ), flags: UInt16(state), fflags: 0, data: 0, udata: nil)]
        let eventCount = events.count
        let success = events.withUnsafeMutableBufferPointer { kevent(queue, $0.baseAddress, Int32(eventCount), nil, 0, nil) >= 0 }
        guard success else { fatalError(DarwinError().message) }
    }
    
    private func events() -> Set<Int32> {
        var timeout = timespec.interval(0.1)
        var events = Array<Darwin.kevent>(repeating: kevent(), count: 1024)
        let success = events.withUnsafeMutableBufferPointer { kevent(queue, nil, 0, $0.baseAddress, 1024, &timeout) >= 0 }
        guard success else { fatalError(DarwinError().message) }
        let mapped: [Int32] = events.compactMap { event in
            guard event.ident == socket.tag && event.filter == EVFILT_READ else { return nil }
            return Int32(event.filter)
        }
        return Set(mapped)
    }
    
}
