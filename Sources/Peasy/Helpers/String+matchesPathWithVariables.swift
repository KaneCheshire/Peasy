//
//  String+matchesPathWithVariables.swift
//  
//
//  Created by Kane Cheshire on 05/12/2019.
//

import Foundation

extension String {
	
	func matches(pathWithVariables: String) -> Bool {
		let constantComponents = split(separator: "/")
		let variableComponents = pathWithVariables.split(separator: "/")
		guard constantComponents.count == variableComponents.count else { return false }
		for (constant, possiblyVariable) in zip(constantComponents, variableComponents) {
			let isVariable = possiblyVariable.starts(with: ":")
			guard !isVariable else { continue }
			if constant != possiblyVariable { return false }
		}
		return true
	}
	
}
