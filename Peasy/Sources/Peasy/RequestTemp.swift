//
//  RequestTemp.swift
//  IntegratedMockTestUITests
//
//  Created by Kane Cheshire on 28/11/2019.
//  Copyright © 2019 kane.codes. All rights reserved.
//

import Foundation

public struct Request: Hashable {
    
    public enum Method: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE" // TODO
    }
    
    public struct QueryParameter: Hashable {
        let name: String
        let value: String?
    }
    
    public typealias Header = Response.Header
    
    public let method: Method
    public let headers: [Header]
    public let path: String
    public let queryParameters: [QueryParameter]
    public let body: Data
    
}
