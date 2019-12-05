//
//  Array+firstPath.swift
//  
//
//  Created by Kane Cheshire on 05/12/2019.
//

import Foundation

extension Array where Element == Server.Rule {
	
	var firstPath: String? {
		return compactMap {
			guard case .path(let path) = $0 else { return nil }
			return path
		}.first
	}
	
}
