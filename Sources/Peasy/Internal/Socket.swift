//
//  Socket.swift
//  Peasy
//
//  Created by Kane Cheshire on 28/11/2019.
//  Copyright © 2019 kane.codes. All rights reserved.
//

import Foundation

final class Socket: Hashable {
    static func == (lhs: Socket, rhs: Socket) -> Bool {
        lhs.tag == rhs.tag
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(tag)
    }
	
	let tag: Int32
	
	init(tag: Int32 = socket(AF_INET6, SOCK_STREAM, 0)) {
		self.tag = tag
	}
	
	func close() {
		shutdown(tag, SHUT_WR)
		Darwin.close(tag)
	}
	
	func bind(port: Int) -> Int {
		enableAddressReuse()
		var address: sockaddr_in6 = .localhost(port: port)
		let size = MemoryLayout<sockaddr_in6>.size
		let success = withUnsafePointer(to: &address) { $0.withMemoryRebound(to: sockaddr.self, capacity: size) { Darwin.bind(tag, $0, socklen_t(size)) >= 0 } }
		guard success else { fatalError(DarwinError().message) }
		listen()
		return boundPort()
	}
	
	private func enableAddressReuse() {
		var reuse = Int32(truncating: true)
		let success = setsockopt(tag, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size)) >= 0
		guard success else { fatalError(DarwinError().message) }
	}
	
	private func listen() {
		let success = Darwin.listen(tag, SOMAXCONN) >= 0
		guard success else { fatalError(DarwinError().message) }
	}
	
	private func boundPort() -> Int {
		var size = socklen_t(MemoryLayout<sockaddr_in6>.size)
		var usedAddress = sockaddr_in6()
		let success = withUnsafeMutablePointer(to: &usedAddress) { $0.withMemoryRebound(to: sockaddr.self, capacity: Int(size)) { getsockname(tag, $0, &size) >= 0 } }
		guard success else { fatalError(DarwinError().message) }
		return Int(usedAddress.sin6_port.bigEndian)
	}
	
	func accept() -> Socket {
		var address = sockaddr_in6()
		var size = socklen_t(MemoryLayout<sockaddr_in6>.size)
		let tag = withUnsafeMutablePointer(to: &address) { $0.withMemoryRebound(to: sockaddr.self, capacity: Int(size)) { Darwin.accept(self.tag, $0, &size) } }
		guard tag >= 0 else { fatalError(DarwinError().message) }
		return Socket(tag: tag)
	}
	
	func read() -> Result<Data, DarwinError> {
		let maxBytes = 1024
		var data = Data(count: maxBytes)
		let bytesRead = data.withUnsafeMutableBytes { recv(tag, $0.baseAddress, maxBytes, 0) }
		guard bytesRead >= 0 else { return .failure(.init()) } // TODO: Could just use this for knowing when to exit a loop rather than the callbacks
		return .success(data[..<bytesRead])
	}
	
	func write(_ data: Data) -> Result<Void, DarwinError> {
		var data = data
		let bytesSent = data.withUnsafeBytes { send(tag, $0.baseAddress, data.count, 0) }
		guard bytesSent >= 0 else { return .failure(.init()) }
		data.removeSubrange(..<bytesSent)
		return data.isEmpty ? .success(()) : write(data)
	}
	
}

private extension in6_addr {
	
	static var localhost: Self {
		var result: in6_addr = in6_addr()
		_ = "::1".withCString { inet_pton(AF_INET6, $0, &result) }
		return result
	}
	
}

private extension sockaddr_in6 {
	
	static func localhost(port: Int) -> Self {
		var address = sockaddr_in6()
		address.sin6_len = UInt8(MemoryLayout<sockaddr_in6>.stride)
		address.sin6_family = sa_family_t(AF_INET6)
		address.sin6_port = UInt16(port).bigEndian
		address.sin6_addr = .localhost
		return address
	}
	
}
