//
//  Loop.swift
//  IntegratedMockTestUITests
//
//  Created by Kane Cheshire on 28/11/2019.
//  Copyright © 2019 kane.codes. All rights reserved.
//

import Foundation

extension timespec {
    
    static func interval(_ interval: TimeInterval) -> timespec {
        var integer = 0.0
        let nsec = Int(modf(interval, &integer) * Double(NSEC_PER_SEC))
        return timespec(tv_sec: Int(interval), tv_nsec: nsec)
    }
    
}

struct DarwinError: Error {
    
    let number: Int32
    var message: String { return String(cString: strerror(errno)) }
    
    init(number: Int32 = errno) {
        self.number = number
    }
    
}

final class OutputLoop {
    
    private let socket: Socket
    private let handler: () -> Void
    private let queue = kqueue()
    private lazy var dispatchQueue = DispatchQueue(label: "OutputLoop: \(socket.tag)", qos: .background)
    
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
        var events = [Darwin.kevent(ident: UInt(socket.tag), filter: Int16(EVFILT_WRITE), flags: UInt16(state), fflags: UInt32(0), data: Int(0), udata: nil)]
        let eventCount = events.count
        let success = events.withUnsafeMutableBufferPointer { kevent(queue, $0.baseAddress, Int32(eventCount), nil, 0, nil) >= 0 }
        guard success else { fatalError(DarwinError().message) }
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
            case EVFILT_WRITE: handler()
            default: break
            }
        }
    }
    
}

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

//class Loop { // TODO: Maybe called a pipe
//	
//	private let outTag: Int32
//	private let inTag: Int32
//	private let selector = Selector()
//	private var callbacks: [Int32: () -> Void] = [:]
//	private var writeCallbacks: [Int32: () -> Void] = [:]
//	private var shouldRun = true
//	
//	init() {
//		var inOut = [Int32](repeating: 0, count: 2) // TODO: Could be better
//		let _ = inOut.withUnsafeMutableBufferPointer {
//			pipe($0.baseAddress)
//		}
//		inTag = inOut[0]
//		outTag = inOut[1]
//		inTag.setNotBlocking()
//		outTag.setNotBlocking()
//	}
//	
//	deinit {
//		stop()
//	}
//	
//	func setReader(_ token: Int32, callback: @escaping () -> Void) {
//		print("Adding reader", token)
//		selector.register(token)
//		callbacks[token] = callback
//	}
//	
//	func removeReader(_ token: Int32) {
//		print("Removing reader", token)
//		guard callbacks[token] != nil else { return }
//		selector.unregister(token)
//		callbacks[token] = nil
//	}
//	
//	func setWriter(_ token: Int32, callback: @escaping () -> Void) {
//		selector.registerWrite(token)
//		writeCallbacks[token] = callback
//	}
//	
//	func removeWriter(_ token: Int32) {
//		guard writeCallbacks[token] != nil else { return }
//		selector.unregisterWrite(token)
//		writeCallbacks[token] = nil
//	}
//	
//	func run() {
//		while shouldRun {
//			runOnce()
//		}
//	}
//	
//	func stop() {
//		shouldRun = false
//	}
//	
//	private func runOnce() {
//		let events = selector.select()
//		guard !events.isEmpty else { return }
//		events.forEach { event in
//			let callback = callbacks[event.key]
//			event.value.forEach { raw in
//				switch raw {
//				case EVFILT_READ:
//					callback!()
//				case EVFILT_WRITE: fatalError()
//				default: break
//				}
//			}
//		}
//	}
//	
//}
