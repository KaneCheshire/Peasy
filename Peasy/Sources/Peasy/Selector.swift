//
//  Selector.swift
//  IntegratedMockTestUITests
//
//  Created by Kane Cheshire on 28/11/2019.
//  Copyright © 2019 kane.codes. All rights reserved.
//

import Foundation

class Selector {
	
	private let queue = kqueue()
	
	init() {
		
	}
	
	deinit {}
	
	func register(_ token: Int32) {
		var events = [Darwin.kevent(ident: UInt(token), filter: Int16(EVFILT_READ), flags: UInt16(EV_ADD), fflags: UInt32(0), data: Int(0), udata: nil)]
		let eventCount = events.count
		let success = events.withUnsafeMutableBufferPointer { pointer in
			kevent(queue, pointer.baseAddress, Int32(eventCount), nil, 0, nil) >= 0
		}
		guard success else { fatalError() }
	}
	
	func registerWrite(_ token: Int32) {
		var events = [Darwin.kevent(ident: UInt(token), filter: Int16(EVFILT_WRITE), flags: UInt16(EV_ADD), fflags: UInt32(0), data: Int(0), udata: nil)]
		let eventCount = events.count
		let success = events.withUnsafeMutableBufferPointer { pointer in
			kevent(queue, pointer.baseAddress, Int32(eventCount), nil, 0, nil) >= 0
		}
		guard success else { fatalError() }
	}
	
	func unregister(_ token: Int32) {
		var events = [Darwin.kevent(ident: UInt(token), filter: Int16(EVFILT_READ), flags: UInt16(EV_DELETE), fflags: UInt32(0), data: Int(0), udata: nil)]
		let eventCount = events.count
		let success = events.withUnsafeMutableBufferPointer { pointer in
			kevent(queue, pointer.baseAddress, Int32(eventCount), nil, 0, nil) >= 0
		}
		guard success else { fatalError() }
	}
	
	func unregisterWrite(_ token: Int32) {
		var events = [Darwin.kevent(ident: UInt(token), filter: Int16(EVFILT_WRITE), flags: UInt16(EV_DELETE), fflags: UInt32(0), data: Int(0), udata: nil)]
		let eventCount = events.count
		let success = events.withUnsafeMutableBufferPointer { pointer in
			kevent(queue, pointer.baseAddress, Int32(eventCount), nil, 0, nil) >= 0
		}
		guard success else { fatalError() }
	}
	
	func select() -> [Int32: Set<Int32>] {
		let timeout: TimeInterval = 0.1
		var integer = 0.0
		let nsec = Int(modf(timeout, &integer) * Double(NSEC_PER_SEC))
		var timeSpec = timespec(tv_sec: Int(timeout), tv_nsec: nsec)
		var events = Array<Darwin.kevent>(repeating: kevent(), count: 1024)
		let success = events.withUnsafeMutableBufferPointer { pointer in
			kevent(queue, nil, 0, pointer.baseAddress, 1024, &timeSpec) >= 0
		}
		guard success else { fatalError() }
		guard !events.isEmpty else { return [:] }
		var tokenEvents: [Int32: Set<Int32>] = [:]
		events.forEach { event in
			let token = Int32(event.ident)
			var events = tokenEvents[token] ?? []
			events.insert(Int32(event.filter))
			tokenEvents[token] = events
		}
		return tokenEvents
	}
	
}
