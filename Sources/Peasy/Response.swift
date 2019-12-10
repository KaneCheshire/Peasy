//
//  Response.swift
//  Peasy
//
//  Created by Kane Cheshire on 28/11/2019.
//  Copyright © 2019 kane.codes. All rights reserved.
//

import Foundation

/// Represents a response to a request that the server can make.
public struct Response: Hashable {
	
	/// The status of the response, i.e. `.ok`, `.notFound` etc.
	public let status: Status
	/// The headers to send in the response.
	public let headers: Set<Header>
	/// The data that makes up the body (can be empty).
	public let body: Data
	
	/// Creates a new response taking raw data as the body.
	/// - Parameters:
	///   - status: The status of the response.
	///   - headers: Any headers to send with the response.
	///   - body: The body of the response (as raw data).
	public init(status: Status, headers: Set<Header> = [], body: Data = Data()) {
		self.status = status
		self.headers = headers
		self.body = body
	}
	
	/// Creates a new response taking a string as the body (which is converted to data for you).
	/// - Parameters:
	///   - status: The status of the response.
	///   - headers: Any headers to send with the response.
	///   - body: The body of the response as a string. This is automatically turned into data for you.
	public init(status: Status, headers: Set<Header> = [], body: String) {
		self = Response(status: status, headers: headers, body: Data(body.utf8))
	}
	
	/// Creates a new response taking an Encodable value as the body, which is automatically encoded into data for you.
	/// - Parameters:
	///   - status: The status of the response.
	///   - headers: Any headers to send with the response.
	///   - body: The body of the response as an Encodable value. This is automatically turned into data for you.
	///   - encoder: An optional encoder you can provide if you need control over the encoding.
	public init<Body: Encodable>(status: Status, headers: Set<Header> = [], body: Body, encoder: JSONEncoder = .prettyPrinted) {
		self = Response(status: status, headers: headers, body: try! encoder.encode(body))
	}
	
	/// Creates a new response taking a URL pointing to some data as the body. The data from the URL is automatically loaded for you.
	/// You can pass a URL to a local file on disk (recommended) but will work with any URL.
	///
	/// - Parameters:
	///   - status: The status of the response.
	///   - headers: Any headers to send with the response.
	///   - body: A URL pointing to some data to be loaded as the data for the body.
	public init(status: Status, headers: Set<Header> = [], body: URL) {
		self = Response(status: status, headers: headers, body: try! Data(contentsOf: body))
	}
	
}

public extension Response {
	
	/// Represents a HTTP status code.
	enum Status: Hashable {
		case ok
		case noContent
		case notFound
		case badRequest
		case unauthorized
		case internalServerError
		case serviceUnavailable
		case code(Int, message: String)
	}
	
	/// Represents a HTTP header.
	struct Header: Hashable {
		let name: String
		let value: String
		
		public init(name: String, value: String) {
			self.name = name
			self.value = value
		}
	}
	
}

public extension Response.Header {
	
	enum Name: String {
		case contentType = "Content-Type"
		case userAgent = "cache-control"
	}
	
	init(name: Name, value: String) {
		self.name = name.rawValue
		self.value = value
	}
	
}

extension Response {
	
	var httpRep: Data {
		let combinedHeaders = [Header(name: "Connection", value: "Closed"),
													 Header(name: "Server", value: "codes.kane.Peasy")] + headers
		let string = "HTTP/1.1 \(status.httpRep)\r\n\(combinedHeaders.httpRep)\r\n\r\n"
		return Data(string.utf8) + body
	}
	
}

private extension Response.Header {
	
	var httpRep: String {
		return "\(name): \(value)"
	}
	
}

private extension Response.Status {
	
	var code: Int {
		switch self {
			case .ok: return 200
			case .noContent: return 204
			case .badRequest: return 400
			case .unauthorized: return 401
			case .notFound: return 404
			case .internalServerError: return 500
			case .serviceUnavailable: return 503
			case .code(let code, _): return code
		}
	}
	
	var message: String {
		switch self {
			case .ok: return "OK"
			case .noContent: return "No Content"
			case .badRequest: return "Bad Request"
			case .unauthorized: return "Unauthorized"
			case .notFound: return "Not Found"
			case .internalServerError: return "Internal Server Error"
			case .serviceUnavailable: return "Service Unavailable"
			case .code(_, let message): return message
		}
	}
	
	var httpRep: String {
		return "\(code) \(message)"
	}
	
}

private extension Array where Element == Response.Header {
	
	var httpRep: String {
		return map { $0.httpRep }.joined(separator: "\r\n")
	}
	
}

public extension JSONEncoder {
	
	static var prettyPrinted: JSONEncoder {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		return encoder
	}
	
}
