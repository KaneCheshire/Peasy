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
	
	mutating func parse(_ data: Data) -> State {
		switch state {
		case .notStarted:
			handle(partialHeader: data)
		case .receivingHeader(partialHeader: let partialHeader):
			handle(partialHeader: partialHeader + data)
		case .receivingBody(fullHeader: let fullHeader, partialBody: let partialBody, progress: _):
			handle(fullHeader: fullHeader, partialBody: partialBody + data)
		case .finished: fatalError()
		}
		return state
	}
	
	// MARK: Private
	
	private mutating func handle(partialHeader: Data) {
		if let rangeOfHeaderEnd = partialHeader.range(of: Data([0x0D, 0x0A, 0x0D, 0x0A])) {
			handle(rangeOfHeaderEnd: rangeOfHeaderEnd, in: partialHeader)
		} else {
			state = .receivingHeader(partialHeader: partialHeader)
		}
	}
	
	private mutating func handle(rangeOfHeaderEnd: Range<Data.Index>, in data: Data) {
		let header = data[data.startIndex ..< rangeOfHeaderEnd.lowerBound]
		let body = data[rangeOfHeaderEnd.upperBound ..< data.endIndex]
		handle(fullHeader: header, partialBody: body)
	}

	private mutating func handle(fullHeader: Data, partialBody: Data) {
		let parsedHeader = parseHeader(fullHeader)
		let length = contentLength(from: parsedHeader)
		if partialBody.count >= length {
			state = .finished(Request(header: parsedHeader, body: partialBody))
		} else {
			let progress = Float(partialBody.count) / Float(length)
			state = .receivingBody(fullHeader: fullHeader, partialBody: partialBody, progress: progress)
		}
	}
	
	private func parseHeader(_ data: Data) -> RequestHeader {
		let header = String(data: data, encoding: .utf8)!
		var lines = header.split(separator: "\r\n")
		let status = lines.removeFirst()
		let statusComponents = status.split(separator: " ")
		let methodRaw = String(statusComponents[0])
		let method = Request.Method(rawValue: methodRaw)!
		let pathWithQuery = String(statusComponents[1])
		let headers = parseHeaders(lines.map { String($0) })
		let path = parsePath(pathWithQuery)
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
