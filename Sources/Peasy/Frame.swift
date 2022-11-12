import Foundation

public enum Frame: DataRepresentable {
    
    case cont
    case text(String)
    case binary(Data)
    
    public struct ClosedInfo {
        let code: UInt16
        let reason: Data?
    }
    case close(ClosedInfo?)
    case ping(Data)
    case pong(Data)
    
    var opCode: UInt8 {
        switch self {
        case .cont:
            return 0x0
        case .text:
            return 0x1
        case .binary:
            return 0x2
        case .close:
            return 0x8
        case .ping:
            return 0x9
        case .pong:
            return 0xA
        }
    }
    
    var dataRepresentation: Data {
        return Data([final_opCode] + mask_length) + payload
    }
    
    private var final_opCode: UInt8 {
        0x80 | opCode
    }
    
    private var payload: Data {
        switch self {
        case .cont:
            return Data()
        case let .text(text):
            return Data(text.utf8)
        case .close(let info):
            guard let info else { return Data() }
            var payload = Data()
            let byte1 = UInt8(info.code >> 8 & 0xFF)
            let byte2 = UInt8(info.code & 0xFF)
            payload.append(contentsOf: [byte1, byte2])
            if let reason = info.reason {
                payload.append(reason)
            }
            return payload
        case let .binary(data), let .ping(data), let .pong(data):
            return data
        }
    }
    
    private var mask_length: [UInt8] {
        if payload.count <= 126 {
            return [UInt8(payload.count)]
        } else if payload.count < UInt16.max {
            return [
                126,
                UInt8(payload.count >> 8 & 0xFF),
                UInt8(payload.count & 0xFF)
            ]
        } else {
            return [
                127,
                UInt8(payload.count >> 56 & 0xFF),
                UInt8(payload.count >> 48 & 0xFF),
                UInt8(payload.count >> 40 & 0xFF),
                UInt8(payload.count >> 32 & 0xFF),
                UInt8(payload.count >> 24 & 0xFF),
                UInt8(payload.count >> 16 & 0xFF),
                UInt8(payload.count >> 08 & 0xFF),
                UInt8(payload.count & 0xFF),
            ]
        }
    }
}



//public struct Frame {
//
//    enum OpCode: UInt8 {
//        case cont = 0x0
//        case text = 0x1
//        case binary = 0x2
//        case close = 0x8
//        case ping = 0x9
//        case pong = 0xA
//    }
//
//    let final: Bool
//    let opCode: OpCode
//    let payload: Data
//
//    var dataRep: Data {
//        return Data([final_opCode] + mask_length) + payload
//    }
//
//    private var final_opCode: UInt8 {
//        (final ? 0x80 : 0x00) | opCode.rawValue
//    }
//
//    private var mask_length: [UInt8] {
//        if payload.count <= 126 {
//            return [UInt8(payload.count)]
//        } else if payload.count < UInt16.max {
//            return [
//                126,
//                UInt8(payload.count >> 8 & 0xFF),
//                UInt8(payload.count & 0xFF)
//            ]
//        } else {
//            return [
//                127,
//                UInt8(payload.count >> 56 & 0xFF),
//                UInt8(payload.count >> 48 & 0xFF),
//                UInt8(payload.count >> 40 & 0xFF),
//                UInt8(payload.count >> 32 & 0xFF),
//                UInt8(payload.count >> 24 & 0xFF),
//                UInt8(payload.count >> 16 & 0xFF),
//                UInt8(payload.count >> 08 & 0xFF),
//                UInt8(payload.count & 0xFF),
//            ]
//        }
//    }
//}
