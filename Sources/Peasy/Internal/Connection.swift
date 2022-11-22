//
//  Connection.swift
//  Peasy
//
//  Created by Kane Cheshire on 28/11/2019.
//  Copyright © 2019 kane.codes. All rights reserved.
//

import Foundation

protocol DataRepresentable {
    
    var dataRepresentation: Data { get }
}

extension Response: DataRepresentable {
    
    var dataRepresentation: Data {
        httpRep // TODO
    }
}

class Connection<Writeable: DataRepresentable>: Hashable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(client)
    }
    
    static func == (lhs: Connection, rhs: Connection) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    let client: Socket
    
    private let eventListener: EventListener
    
    init(
        client: Socket,
        eventListener: EventListener
    ) {
        self.client = client
        self.eventListener = eventListener
        eventListener.register(client) { [weak self] in // TODO: Don't want this to be registered more than once when changing to ws
            self?.handleDataAvailable()
        }
    }
    
    func close() {
//        eventListener.unregister(client)
//        client.close()
    }
    
    func parse(_ data: Data) {
        fatalError("\(#function) should be overridden")
    }
    
    func send(_ writeable: Writeable) {
        switch client.write(writeable.dataRepresentation) {
        case .success:
            break
        case let .failure(error):
            fatalError(error.localizedDescription)
        }
    }
    
    private func handleDataAvailable() {
        switch client.read() {
        case .success(let data):
            parse(data)
        case .failure(let error):
            fatalError(error.message)
        }
    }
}

final class HTTPConnection: Connection<Response> {
    
    private var parser = RequestParser()
    private let onRequestReceived: (Request, HTTPConnection) -> Void
    private let eventListener: EventListener
    
    init(
        client: Socket,
        eventListener: EventListener,
        onRequestReceived: @escaping (Request, HTTPConnection) -> Void
    ) {
        self.eventListener = eventListener
        self.onRequestReceived = onRequestReceived
        super.init(client: client, eventListener: eventListener)
    }
    
    override func parse(_ data: Data) {
        switch parser.parse(data) {
        case let .finished(request):
            onRequestReceived(request, self)
        case .notStarted, .receivingBody, .receivingHeader:
            break
        }
    }
    
    func upgradeToWebSocket(onFrameReceived: @escaping (Frame, WebSocketConnection) -> Void) -> WebSocketConnection { // TODO: Move sending response here?
        WebSocketConnection(client: client, eventListener: eventListener, onFrameReceived: onFrameReceived)
    }
}

final class WebSocketConnection: Connection<Frame> {
    
    private let parser = FrameParser() // TODO: Inject and test
    private let onFrameReceived: (Frame, WebSocketConnection) -> Void
    private var isOkayToSendClose = false
    
    init(
        client: Socket,
        eventListener: EventListener,
        onFrameReceived: @escaping (Frame, WebSocketConnection) -> Void
    ) {
        self.onFrameReceived = onFrameReceived
        super.init(client: client, eventListener: eventListener)
    }
    
    override func parse(_ data: Data) {
        let output = parser.parse(data: data)
        if let frame = output.0 {
            switch frame {
            case .close where isClosing:
                super.close()
            default:
                onFrameReceived(frame, self)
            }
        }
        if let nextData = output.1 {
            parse(nextData)
        }
    }
    
    override func close() {
        close(with: nil)
//        super.close()
    }
    
    var isClosing: Bool = false
    
    override func send(_ writeable: Frame) {
        switch writeable {
        case .close where !isOkayToSendClose:
            return assertionFailure("Don't send close yourself, call close(with:) instead which closes the socket properly too.")
        case .close, .cont, .text, .binary, .ping, .pong:
            super.send(writeable)
        }
    }
    
    func close(with info: Frame.ClosedInfo?) {
        okToSendClose {
            isClosing = true
            send(.close(info))
        }
//        super.close()
    }
    
    private func okToSendClose(_ block: () -> Void) {
        isOkayToSendClose = true
        block()
        isOkayToSendClose = false
    }
}



//protocol ConnectionType {
//    
//    associatedtype AdapterType: Adapter
//    associatedtype ParsedValue
//    
//    func parse(data: Data) -> ParsedValue
//}
//
//protocol Adapter {
//    
//    init(client: Socket)
//}
//
//struct HTTPConnectionType: ConnectionType {
//    
//    typealias AdapterType = Connection.HTTPAdapter
//    
//    private var parser: RequestParser
// 
//    func parse(data: Data) -> Response? {
//        // TODO
//    }
//}
//
//struct WebSocketConnectionType: ConnectionType {
//    
//    typealias AdapterType = Connection.WebSocketAdapter
//    
//    private let parser: FrameParser
//    
//    func parse(data: Data) -> Frame? {
//        parser.parse(data: data)
//    }
//}
//
//final class Connection {
//    
//    final class HTTPAdapter: Adapter {
//        
//        private let client: Socket
//        
//        init(client: Socket) {
//            self.client = client
//        }
//        
//        func respond(with response: Response) {
//            switch client.write(response.httpRep) {
//                case .success: break
//                case .failure(let error): fatalError(error.message)
//            }
//        }
//    }
//    
//    final class WebSocketAdapter: Adapter {
//        
//        private let client: Socket
//        
//        init(client: Socket) {
//            self.client = client
//        }
//        
//        func send(_ frame: Frame) {
//            switch client.write(frame.dataRep) {
//            case .success: break
//            case .failure(let error): fatalError(error.message)
//            }
//        }
//    }
//    
////    enum ConnectionType {
////        typealias HTTPEventHandler = (Request?, HTTPAdapter) -> Void
////        case http(HTTPEventHandler)
////
////        typealias WebSocketEventHandler = (Frame?, WebSocketAdapter) -> Void
////        case websocket(WebSocketEventHandler)
////    }
//    
//	
//    private var type: any ConnectionType
//	private let client: Socket
//	private var requestParser = RequestParser()
//    private let frameParser = FrameParser()
//	private let eventListener: EventListener
//	
//    init(client: Socket, eventListener: EventListener) {
//		self.eventListener = eventListener
//		
//	}
//    
//    func open<CT: ConnectionType>(
//        as type: CT,
//        with client: Socket
//    ) -> CT.AdapterType {
//        let adapter = change(to: type)
//        eventListener.register(client) { [weak self] in
//            self?.handleDataAvailable()
//        }
//        return adapter
//    }
//	
////	deinit {
////		eventListener.unregister(client) // TODO: Might be better to explicitly close, that way we can create new copies of connections with a different type
////		client.close()
////	}
//    
//    
//    func change<CT: ConnectionType>(to type: CT) -> CT.AdapterType {
//        self.type = type
//        return CT.AdapterType(client: client)
////        self.type = type
//        
////        switch type {
////        case let .http(handler):
////            handler(nil, .init(client: client)) // Provides an initial handler
////        case let .websocket(handler):
////            handler(nil, .init(client: client))
////        }
//    }
//    
//    func close() {
//        switch type {
//        case .http: break
//        case .websocket:
//            let adapter = WebSocketAdapter(client: client)
//            let closeFrame = Frame(final: true, opCode: .close, payload: Data()) // TODO: Need to be able to pass a reason
//            adapter.send(closeFrame)
//        }
//        eventListener.unregister(client)
//        client.close()
//    }
//	
//	private func handleDataAvailable() {
//		switch client.read() {
//			case .success(let data): handle(data)
//			case .failure(let error): fatalError(error.message)
//		}
//	}
//	
//	private func handle(_ data: Data) {
//        type.parse(data: data)
////        switch type {
////        case .http(let handler):
////            if data.isEmpty { // TODO: When might this happen?
////                handler(nil, .init(client: client))
////            } else {
////                parse(data, handler: handler)
////            }
////        case .websocket(let handler):
////            if let frame = frameParser.parse(data: data) {
////                handler(frame, WebSocketAdapter(client: client))
//////                switch frame.opCode {
//////                case .binary: break
//////                case .text: break
//////                case .cont: break
//////                case .close:
//////                    let response = Frame(final: true, opCode: .close, payload: .init())
//////                    adapter.send(response) // TODO: Is this needed?? Probably not.
//////                    client.close()
//////                case .ping:
//////                    // TODO: Here's where we need to make things configurable
//////                    let response = Frame(final: true, opCode: .pong, payload: frame.payload)
//////                    adapter.send(response)
//////                case .pong: break
//////                }
////            }
//        }
//	}
//	
////    private func parse(_ data: Data, handler: ConnectionType.HTTPEventHandler) {
////        switch requestParser.parse(data) {
////        case .finished(let request):
////            let adapter = HTTPAdapter(client: client)
////            handler(request, adapter)
////        case .notStarted, .receivingHeader, .receivingBody: break
////        }
////	}
//	
//}
//
//extension Connection: Hashable {
//	
//	static func == (lhs: Connection, rhs: Connection) -> Bool {
//        return lhs.client == rhs.client
//	}
//	
//	func hash(into hasher: inout Hasher) {
//        hasher.combine(client)
//	}
//	
//}
