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
    private lazy var dispatchQueue = DispatchQueue(label: "InputLoop: \(socket.tag)", qos: .background)
    
    init(socket: Socket, _ handler: @escaping () -> Void) {
        self.socket = socket
        self.handler = handler
        setState(EV_ADD)
        run()
    }
    
    deinit { setState(EV_DELETE) }
    
    private func run() {
        dispatchQueue.async { [weak self] in
            guard let self = self else { return }
            let events = self.events()
            self.handle(events)
            self.run()
        }
    }
    
    private func setState(_ state: Int32) {
        var events = [Darwin.kevent(ident: UInt(socket.tag), filter: Int16(EVFILT_READ), flags: UInt16(state), fflags: UInt32(0), data: Int(0), udata: nil)]
        let eventCount = events.count
        let success = events.withUnsafeMutableBufferPointer { kevent(queue, $0.baseAddress, Int32(eventCount), nil, 0, nil) >= 0 }
    }
    
    private func events() -> Set<Int32> {
        var timeout = timespec.interval(0.1)
        var events = Array<Darwin.kevent>(repeating: kevent(), count: 1024)
        let success = events.withUnsafeMutableBufferPointer { kevent(queue, nil, 0, $0.baseAddress, 1024, &timeout) >= 0 }
        guard success else { fatalError() }
        let mapped = events.map { Int32($0.filter) }
        return Set(mapped)
    }
    
    private func handle(_ events: Set<Int32>) {
        events.forEach { event in
            switch event {
            case EVFILT_READ: handler()
            default: break
            }
        }
    }
    
}
