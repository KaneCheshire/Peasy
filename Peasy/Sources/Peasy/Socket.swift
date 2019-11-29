//
//  Socket.swift
//  IntegratedMockTestUITests
//
//  Created by Kane Cheshire on 28/11/2019.
//  Copyright © 2019 kane.codes. All rights reserved.
//

import Foundation

class Socket {
	
	let tag: Int32
	
	init() {
		tag = socket(AF_INET6, SOCK_STREAM, 0)
		tag.setNotBlocking()
	}
	
	init(sock: Int32) {
		self.tag = sock
		sock.setNotBlocking()
	}
	
	deinit {
		cleanup()
	}
	
	func cleanup() {
		shutdown(tag, SHUT_WR)
		close(tag)
	}
	
	func bind(port: Int, interface: String) {
		print("Binding port...", port, interface)
		var reuse: Int32 = 1
		guard setsockopt(tag, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size)) >= 0 else { fatalError() }
		var address = sockaddr_in6()
		address.sin6_len = UInt8(MemoryLayout<sockaddr_in6>.stride)
		address.sin6_family = sa_family_t(AF_INET6)
		address.sin6_port = UInt16(port).bigEndian
		address.sin6_flowinfo = 0
		address.sin6_addr = ipAddressToStruct(address: interface)
		address.sin6_scope_id = 0
		let size = socklen_t(MemoryLayout<sockaddr_in6>.size)
		let success = withUnsafePointer(to: &address) { pointer in
			pointer.withMemoryRebound(to: sockaddr.self, capacity: Int(size)) { pointer in
				Darwin.bind(tag, pointer, size) >= 0
			}
		}
		guard success else { fatalError() }
		print("Port binded", port, interface)
	}
	
	func listen() {
		print("Listening...")
		let success = Darwin.listen(tag, Int32(SOMAXCONN)) != -1
		guard success else { fatalError() }
		print("Listening")
	}
	
	func accept() -> Socket {
		print("Accepting...")
		var address = sockaddr_in6()
		var size = socklen_t(MemoryLayout<sockaddr_in6>.size)
		let sock = withUnsafeMutablePointer(to: &address) { pointer in
			pointer.withMemoryRebound(to: sockaddr.self, capacity: Int(size)) { pointer in
				Darwin.accept(self.tag, pointer, &size)
			}
		}
		guard sock >= 0 else { fatalError() }
		print("Accepted sock", sock)
		return Socket(sock: sock)
	}
	
	enum ReadError: Error {
		case number(Int32)
	}
	
	func receive(size: Int) -> Result<Data, ReadError> {
		var bytes = Data(count: size)
		let bytesRead = bytes.withUnsafeMutableBytes { pointer in
			recv(tag, pointer, size, Int32(0))
		}
		if bytesRead >= 0 {
			let data = bytes.subdata(in: 0..<bytesRead)
			return .success(data)
		} else {
			return .failure(.number(errno))
		}
	}
	
	enum WriteError: Error {
		case number(Int32)
	}
	
	func send(_ data: Data) -> Result<Int, WriteError>  {
		let bytesSent = data.withUnsafeBytes { pointer in
			Darwin.send(tag, pointer, data.count, 0)
		}
		if bytesSent >= 0 {
			return .success(bytesSent)
		} else {
			return .failure(.number(errno))
		}
	}
	
	private func ipAddressToStruct(address: String) -> in6_addr {
		var result: in6_addr = in6_addr()
		_ = address.withCString { inet_pton(AF_INET6, $0, &result) } // TODO: Don't really understand this yet...
		return result
	}
	
}
