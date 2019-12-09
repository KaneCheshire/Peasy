//
//  Server.Rule+verifyRequest.swift
//  
//
//  Created by Kane Cheshire on 05/12/2019.
//

import Foundation

extension Server.Rule {
	
	func verify(_ request: Request) -> Bool {
		switch self {
			case .method(matches: let method): return request.method == method
			case .path(matches: let path): return request.path.matches(pathWithVariables: path)
			case .headers(contain: let header): return request.headers.contains(header)
			case .queryParameters(contain: let queryParam): return request.queryParameters.contains(queryParam)
			case .body(matches: let body): return request.body == body
			case .custom(let handler): return handler(request)
		}
	}
	
}
