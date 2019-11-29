//
//  Loop.swift
//  IntegratedMockTestUITests
//
//  Created by Kane Cheshire on 28/11/2019.
//  Copyright © 2019 kane.codes. All rights reserved.
//

import Foundation

class Loop { // TODO: Maybe called a pipe
	
	private let outTag: Int32
	private let inTag: Int32
	private let selector = Selector()
	private var callbacks: [Int32: () -> Void] = [:]
	private var writeCallbacks: [Int32: () -> Void] = [:]
    private var shouldRun = true
	
	init() {
		var inOut = [Int32](repeating: 0, count: 2) // TODO: Could be better
		let _ = inOut.withUnsafeMutableBufferPointer {
			pipe($0.baseAddress)
		}
		inTag = inOut[0]
        outTag = inOut[1]
        inTag.setNotBlocking()
		outTag.setNotBlocking()
	}
	
	deinit {
		stop()
	}
	
	func setReader(_ token: Int32, callback: @escaping () -> Void) {
		print("Adding reader", token)
		selector.register(token)
		callbacks[token] = callback
	}
	
	func removeReader(_ token: Int32) {
		print("Removing reader", token)
		guard callbacks[token] != nil else { return }
		selector.unregister(token)
		callbacks[token] = nil
	}
	
	func setWriter(_ token: Int32, callback: @escaping () -> Void) {
		selector.registerWrite(token)
		writeCallbacks[token] = callback
	}
	
	func removeWriter(_ token: Int32) {
		guard writeCallbacks[token] != nil else { return }
		selector.unregisterWrite(token)
		writeCallbacks[token] = nil
	}
	
	
	
	func run() {
		while shouldRun {
			runOnce()
		}
	}
	
	func stop() {
		shouldRun = false
	}
	
	private func runOnce() {
		let events = selector.select()
		guard !events.isEmpty else { return }
		events.forEach { event in
			let callback = callbacks[event.key]
			event.value.forEach { raw in
				switch raw {
				case EVFILT_READ:
					callback!()
				case EVFILT_WRITE: fatalError()
				default: break
				}
			}
		}
	}
	
}
