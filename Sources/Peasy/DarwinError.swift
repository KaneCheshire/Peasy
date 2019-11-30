//
//  DarwinError.swift
//  
//
//  Created by Kane Cheshire on 30/11/2019.
//

import Foundation

struct DarwinError: Error {
    
    let number: Int32
    var message: String { return String(cString: strerror(errno)) }
    
    init(number: Int32 = errno) {
        self.number = number
    }
    
}
