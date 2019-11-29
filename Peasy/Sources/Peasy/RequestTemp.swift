//
//  RequestTemp.swift
//  IntegratedMockTestUITests
//
//  Created by Kane Cheshire on 28/11/2019.
//  Copyright © 2019 kane.codes. All rights reserved.
//

import Foundation

public struct Request {
    
    public enum Method: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
    
    public typealias Header = Response.Header
    
    public let method: Method
    public let path: String
    public let headers: [Header]
    public let body: Data
    
}
