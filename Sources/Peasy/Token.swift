//
//  File.swift
//  
//
//  Created by Kane Cheshire on 29/11/2019.
//

import Foundation

extension Int32 {
	
	@discardableResult
	func setNotBlocking() -> Int32 {
		let flags = fcntl(self, F_GETFL, 0)
		return fcntl(self, F_SETFL, flags | O_NONBLOCK)
	}
	
}
