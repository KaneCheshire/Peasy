//
//  DispatchQueue+shared.swift
//  Peasy
//
//  Created by Kane Cheshire on 28/04/2020.
//

import Foundation

public extension DispatchQueue {
    
	static let shared = DispatchQueue(label: "codes.kane.Peasy", qos: .background, target: nil)
    
}
