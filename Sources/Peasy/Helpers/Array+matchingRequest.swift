//
//  Array+matchingRequest.swift
//  
//
//  Created by Kane Cheshire on 05/12/2019.
//

import Foundation

extension Array where Element == Server.Configuration {
	
	func matching(_ request: Request) -> Element? {
		return first { config in
			let nonMatchingRule = config.rules.first { $0.verify(request) == false }
			return nonMatchingRule == nil
		}
	}
	
}
