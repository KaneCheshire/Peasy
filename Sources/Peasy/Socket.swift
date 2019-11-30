//
//  Socket.swift
//  IntegratedMockTestUITests
//
//  Created by Kane Cheshire on 28/11/2019.
//  Copyright © 2019 kane.codes. All rights reserved.
//

import Foundation

final class Socket {
	
    let tag: Int32
	
	init(tag: Int32 = socket(AF_INET6, SOCK_STREAM, 0)) {
		self.tag = tag
		tag.setNotBlocking()
	}
	
	deinit {
        print("Closing socket", tag)
		shutdown(tag, SHUT_WR)
        close(tag)
	}
	
	func bind(port: Int, interface: String) {
        var reuse: Int32 = 1
        guard setsockopt(tag, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size)) >= 0 else { fatalError(DarwinError().message) }
        var address = sockaddr_in6()
        address.sin6_len = UInt8(MemoryLayout<sockaddr_in6>.stride)
        address.sin6_family = sa_family_t(AF_INET6)
        address.sin6_port = UInt16(port).bigEndian
        address.sin6_addr = .from(interface)
        let size = socklen_t(MemoryLayout<sockaddr_in6>.size)
        let success = withUnsafePointer(to: &address) { $0.withMemoryRebound(to: sockaddr.self, capacity: Int(size)) { Darwin.bind(tag, $0, size) >= 0 } }
        guard success else { fatalError(DarwinError().message) }
        print("Bound to port", port, interface)
	}
	
	func listen() {
		let success = Darwin.listen(tag, Int32(SOMAXCONN)) >= 0
        guard success else { fatalError(DarwinError().message) }
		print("Listening on socket", tag)
	}
	
	func accept() -> Socket {
        var address = sockaddr_in6()
        var size = socklen_t(MemoryLayout<sockaddr_in6>.size)
        let tag = withUnsafeMutablePointer(to: &address) { $0.withMemoryRebound(to: sockaddr.self, capacity: Int(size)) { Darwin.accept(self.tag, $0, &size) } }
        guard tag >= 0 else { fatalError(DarwinError().message) }
        print("Accepted incoming socket", tag)
		return Socket(tag: tag)
	}
	
	func read() -> Result<Data, DarwinError> {
        let maxBytes = 1024
		var data = Data(count: maxBytes)
        let bytesRead = data.withUnsafeMutableBytes { recv(tag, $0, maxBytes, 0) }
        guard bytesRead >= 0 else { return .failure(.init()) }
        return .success(data[..<bytesRead]) // TODO: If data is empty it's finished, should handle that
	}
    
    func write(_ data: Data) -> Result<Void, DarwinError> {
        var data = data
        let bytesSent = data.withUnsafeBytes { Darwin.send(tag, $0, data.count, 0) }
        guard bytesSent >= 0 else { return .failure(.init()) }
        data.removeSubrange(..<bytesSent)
        return data.isEmpty ? .success(()) : write(data)
    }
	
}

extension in6_addr {
    
    static func from(_ interface: String) -> in6_addr {
        var result: in6_addr = in6_addr()
        _ = interface.withCString { inet_pton(AF_INET6, $0, &result) } // TODO: Don't really understand this yet...
        return result
    }
    
}
