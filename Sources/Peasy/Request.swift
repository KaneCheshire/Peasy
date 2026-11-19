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
	
	private var variables: [String: String] = [:]
	
	/// Returns a variable value for a key.
	/// Variable values are populated by requests matching a `.path` rule with variables, i.e.
	/// `"/path/:variable_name"`, which you would then be able to get the value of with
	/// `request["variable_name"]`.
	public subscript(_ key: String) -> String {
		guard let value = variables[key] else { fatalError("No value found for \(key)") }
		return value
	}
	
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
	public struct QueryParameter: Hashable {
		public let name: String
		public let value: String?
		
		public init(name: String, value: String?) {
			self.name = name
			self.value = value
		}
	}
	
	/// Represents a header in a request.
	typealias Header = Response.Header
	
}

extension Request {
	
	init(method: Method, headers: [Header], path: String, queryParameters: [QueryParameter], body: Data) {
		self.method = method
		self.headers = headers
		self.path = path
		self.queryParameters = queryParameters
		self.body = body
	}
	
	init(header: RequestParser.RequestHeader, body: Data) {
		self = Request(method: header.method, headers: header.headers, path: header.path, queryParameters: header.queryParams, body: body)
	}
	
	mutating func updateVariables(from rules: [Server.Rule]) {
		guard let pathWithVariables = rules.firstPath else { return }
		guard let urlWithVariables = URL(string: pathWithVariables) else { fatalError("Path must be a valid URL path, not \(pathWithVariables)") }
		guard let url = URL(string: path) else { fatalError("Path must be a valid URL path, not \(path)") }
		variables = url.variableValues(from: urlWithVariables)
	}
	
}
