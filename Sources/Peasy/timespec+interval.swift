//
//  timespec+interval.swift
//  
//
//  Created by Kane Cheshire on 30/11/2019.
//

import Foundation

extension timespec {
    
    static func interval(_ interval: TimeInterval) -> timespec {
        var integer = 0.0
        let nsec = Int(modf(interval, &integer) * Double(NSEC_PER_SEC))
        return timespec(tv_sec: Int(interval), tv_nsec: nsec)
    }
    
}
