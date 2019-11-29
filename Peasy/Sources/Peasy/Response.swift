//
//  Response.swift
//  IntegratedMockTestUITests
//
//  Created by Kane Cheshire on 28/11/2019.
//  Copyright © 2019 kane.codes. All rights reserved.
//

import Foundation

public struct Response: Hashable {
    
    public enum Status: Int {
        case ok = 200
        case notFound = 401
        case internalServerError = 500
    }
    
    public struct Header: Hashable { // TODO: Provide defaults like content type etc
        let name: String
        let value: String
        
        public enum Name: String {
            case contentType = "Content-Type"
            case userAgent = "cache-control" // TODO: Might just be request only which would be a good case for two different Header structs
        }
    }
    
    let status: Status
    let headers: [Header]
    let body: String // TODO: Support sending image data
    
    public init(status: Status, headers: [Header] = [], body: String = "") {
        self.status = status
        self.headers = headers
        self.body = body
    }
    
}

public extension Response.Header {
    
    init(name: Name, value: String) {
        self.name = name.rawValue
        self.value = value
    }
    
}

extension Response {
    
    var httpRep: String {
        let combinedHeaders = [Header(name: "Connection", value: "Closed"),
                               Header(name: "Server", value: "Sprite"),
                               Header(name: "Content-Type", value: "text/html; charset=UTF-8")] + headers
        return "HTTP/1.1 \(status.httpRep)\r\n\(combinedHeaders.httpRep)\r\n\r\n\(body)"
    }
    
}

extension Response.Header {
    
    var httpRep: String {
        return "\(name): \(value)"
    }
    
}

extension Response.Status {
    
    var httpRep: String {
        return "\(rawValue) \(textRep)"
    }
    
    var textRep: String {
        switch self {
            case .ok: return "OK"
            case .notFound: return "Not Found"
            case .internalServerError: return "Internal Server Error"
        }
    }
    
}

extension Array where Element == Response.Header {
    
    var httpRep: String {
        return map { $0.httpRep }.joined(separator: "\r\n")
    }
    
}
