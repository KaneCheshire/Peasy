//
//  Array+matchingRequest.swift
//  
//
//  Created by Kane Cheshire on 05/12/2019.
//

import Foundation

extension Array where Element == Server.Configuration {
    
    subscript(_ request: Request) -> Element? {
        return filter { $0.matches(request) }.last
    }
	
}

extension Server.Configuration {
    
    func matches(_ request: Request) -> Bool {
        let isWebSocket = request[header: "Upgrade"] == "websocket"
        guard isWebSocket && self.isWebSocket else { return false }
        return rules.filter { !$0.verify(request) }.isEmpty
    }
    
    var isWebSocket: Bool {
        switch responseType {
        case .webSocket: return true
        case .http: return false
        }
    }
    
}

//extension Array where Element == Server.WebSocket {
//    
//    subscript(_ request: Request) -> Element? {
//        return filter { $0.matches(request) }.last
//    }
//    
//}
//
//extension Server.WebSocket {
//    
//    func matches(_ request: Request) -> Bool {
//        return rules.filter { !$0.verify(request) }.isEmpty
//    }
//    
//}
