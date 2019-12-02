//
//  Response.swift
//  Peasy
//
//  Created by Kane Cheshire on 28/11/2019.
//  Copyright © 2019 kane.codes. All rights reserved.
//

import Foundation

public struct Response: Hashable {
	
	let status: Status
	let headers: [Header]
	let body: Data
	
	public init(status: Status, headers: [Header] = [], body: Data = Data()) {
		self.status = status
		self.headers = headers
		self.body = body
	}
	
	public init(status: Status, headers: [Header] = [], body: String) {
		self = Response(status: status, headers: headers, body: Data(body.utf8))
	}
	
	public init<Body: Encodable>(status: Status, headers: [Header] = [], body: Body, encoder: JSONEncoder = .prettyPrinted) {
		self = Response(status: status, headers: headers, body: try! encoder.encode(body))
	}
	
}

public extension Response {
	
	enum Status: Hashable {
		case ok
		case notFound
		case badRequest
		case unauthorized
		case internalServerError
		case serviceUnavailable
		case code(Int, message: String)
	}
	
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
													 Header(name: "Server", value: "Sprite"),
													 Header(name: "Content-Type", value: "text/html; charset=UTF-8")] + headers
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
