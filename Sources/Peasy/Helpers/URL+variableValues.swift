//
//  URL+variableValues.swift
//  
//
//  Created by Kane Cheshire on 05/12/2019.
//

import Foundation

extension URL {
	
	func variableValues(from urlWithVariables: URL) -> [String: String] {
		let urlComponents = pathComponents
		let variableURLComponents = urlWithVariables.pathComponents
		guard urlComponents.count == variableURLComponents.count else { return [:] }
		return variableURLComponents.variableIndices.reduce(into: [:]) { result, index in
			let key = variableURLComponents[index].replacingOccurrences(of: ":", with: "")
			result[key] = urlComponents[index]
		}
	}
	
}
