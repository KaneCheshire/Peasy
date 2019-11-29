//
//  File.swift
//  
//
//  Created by Kane Cheshire on 29/11/2019.
//

import Foundation

typealias Token = Int32
typealias Outcome = Int32

extension Token {
	
	@discardableResult
	func setNotBlocking() -> Outcome {
		let flags = fcntl(self, F_GETFL, 0)
		return fcntl(self, F_SETFL, flags | O_NONBLOCK)
	}
	
}
