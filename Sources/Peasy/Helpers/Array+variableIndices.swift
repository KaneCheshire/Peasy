//
//  Array+variableIndices.swift
//  
//
//  Created by Kane Cheshire on 05/12/2019.
//

import Foundation

extension Array where Element == String {
	
	var variableIndices: [Index] {
		return enumerated().compactMap { index, component in
			component.starts(with: ":") ? index : nil
		}
	}
	
}
