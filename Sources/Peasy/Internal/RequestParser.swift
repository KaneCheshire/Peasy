//
//  HeaderParser.swift
//  Peasy
//
//  Created by Kane Cheshire on 28/11/2019.
//  Copyright © 2019 kane.codes. All rights reserved.
//

import Foundation

struct RequestParser {
	
	// MARK: - Custom Types -
	// MARK: Internal
	
	enum State {
		case notStarted
		case receivingHeader(partialHeader: Data)
		case receivingBody(fullHeader: Data, partialBody: Data, progress: Float)
		case finished(Request)
	}
	
	typealias RequestHeader = (method: Request.Method, path: String, headers: [Request.Header], queryParams: [Request.QueryParameter])
	
	// MARK: - Properties -
	// MARK: Private
	
	private var state: State = .notStarted
	
	// MARK: - Functions -
	// MARK: Internal
	
	mutating func parse(_ data: Data) -> State { // TODO
		switch state {
		case .notStarted:
			state = handle(partialHeader: data)
		case .receivingHeader(partialHeader: let partialHeader):
			state = handle(partialHeader: partialHeader + data)
		case .receivingBody(fullHeader: let fullHeader, partialBody: let partialBody, progress: _):
			state = handle(fullHeader: fullHeader, partialBody: partialBody + data)
		case .finished: fatalError()
		}
		return state
	}
	
	// MARK: Private
	
	private func handle(partialHeader: Data) -> State {
		if let rangeOfHeaderEnd = partialHeader.range(of: Data([0x0D, 0x0A, 0x0D, 0x0A])) {
			let header = partialHeader[partialHeader.startIndex ..< rangeOfHeaderEnd.lowerBound]
			let body = partialHeader[rangeOfHeaderEnd.upperBound ..< partialHeader.endIndex]
			return handle(fullHeader: header, partialBody: body)
		} else {
			return .receivingHeader(partialHeader: partialHeader)
		}
	}

	private func handle(fullHeader: Data, partialBody: Data) -> State {
		let parsedHeader = parseHeader(fullHeader)
		let length = contentLength(from: parsedHeader)
		if partialBody.count >= length {
			return .finished(Request(header: parsedHeader, body: partialBody))
		} else {
			let progress = Float(partialBody.count) / Float(length)
			return .receivingBody(fullHeader: fullHeader, partialBody: partialBody, progress: progress)
		}
	}
	
	private func parseHeader(_ data: Data) -> RequestHeader {
		let header = String(data: data, encoding: .utf8)!
		var lines = header.split(separator: "\r\n")
		let status = lines.removeFirst()
		let statusComponents = status.split(separator: " ")
		let methodRaw = String(statusComponents[0])
		let pathWithQuery = String(statusComponents[1])
		
		let method = Request.Method(rawValue: methodRaw)!
		let path = parsePath(pathWithQuery)
		let headers = parseHeaders(lines.map { String($0) })
		let queryParams = parseQueryParams(pathWithQuery)
		return (method, path, headers, queryParams)
	}
	
	private func parsePath(_ pathWithQuery: String) -> String {
		return String(pathWithQuery.split(separator: "?").first!)
	}
	
	private func parseQueryParams(_ path: String) -> [Request.QueryParameter] {
		guard let range = path.range(of: "?") else { return [] }
		let params = path[range.upperBound ..< path.endIndex].split(separator: "&")
		return params.map { param in
			let paramComponents = param.split(separator: "=")
			let name = String(paramComponents[0])
			let value = paramComponents.count > 1 ? String(paramComponents[1]) : nil
			return Request.QueryParameter(name: name, value: value)
		}
	}
	
	private func parseHeaders(_ lines: [String]) -> [Request.Header] {
		return lines.map { line in
			let headerComponents = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
			let name = headerComponents[0].trimmingCharacters(in: .whitespacesAndNewlines)
			let value = headerComponents[1].trimmingCharacters(in: .whitespacesAndNewlines)
			return Request.Header(name: name, value: value)
		}
	}
	
	private func contentLength(from parsedHeader: RequestHeader) -> Int {
		let contentHeader = parsedHeader.headers.first { $0.name.lowercased() == "content-length" }
		return Int(contentHeader?.value ?? "") ?? 0
	}
	
}
