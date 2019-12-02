//
//  Request.swift
//  Peasy
//
//  Created by Kane Cheshire on 28/11/2019.
//  Copyright © 2019 kane.codes. All rights reserved.
//

import Foundation

/// Represents a request received from a client (i.e. browser or app).
public struct Request: Hashable {
	
	/// The method of the request, i.e. `.get`, `.post` etc.
	public let method: Method
	/// Any headers received from the request.
	public let headers: [Header]
	/// The path of the request, i.e. `/path/to/endpoint`
	public let path: String
	/// Any query parameters received from the request.
	public let queryParameters: [QueryParameter]
	/// The body data of the request (might be empty).
	public let body: Data
	
}

public extension Request {
	
	/// Represents the method of the request.
	enum Method: String {
		case get = "GET"
		case post = "POST"
		case put = "PUT"
		case delete = "DELETE"
		case head = "HEAD"
	}
	
	/// Represents a query parameter in the request.
	struct QueryParameter: Hashable {
		let name: String
		let value: String?
		
		public init(name: String, value: String?) {
			self.name = name
			self.value = value
		}
	}
	
	/// Represents a header in a request.
	typealias Header = Response.Header
	
}
