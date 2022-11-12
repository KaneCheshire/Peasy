import Foundation

final class FrameParser {
    
    struct FrameHeader {
        
        enum OpCode: UInt8 {
            case cont = 0x0
            case text = 0x1
            case binary = 0x2
            case close = 0x8
            case ping = 0x9
            case pong = 0xA
        }
        
        let final: Bool
        let opCode: OpCode
        let payloadLength: UInt64
        let mask: Data
    }
    
    enum Stage {
        case receivingInfo
        case receivingPayload(frameHeader: FrameHeader, partialPayload: Data)
    }
    
    private var stage: Stage = .receivingInfo
    
    func parse(data: Data) -> Frame? {
        switch stage {
        case .receivingInfo:
            guard data.count >= 2 else {
                assertionFailure()
                return nil
            }
            let final = (data[0] & 0x80) != 0
            let opCodeRaw = (data[0] & 0x0F)
            
            let lengthIndicator = data[1] & 0x7F
            let payloadLength: UInt64
            let maskRange: Range<Int>
            if lengthIndicator == 126 {
                let byte1 = UInt64(data[2]) << 8
                let byte2 = UInt64(data[3])
                payloadLength = UInt64(littleEndian: byte1 | byte2) // 16bits
                maskRange = 4 ..< 8
            } else if lengthIndicator == 127 {
                let byte1 = UInt64(data[2]) << 56
                let byte2 = UInt64(data[3]) << 48
                let byte3 = UInt64(data[4]) << 40
                let byte4 = UInt64(data[5]) << 32
                let byte5 = UInt64(data[6]) << 24
                let byte6 = UInt64(data[7]) << 16
                let byte7 = UInt64(data[8]) << 8
                let byte8 = UInt64(data[9])
                payloadLength = UInt64(littleEndian: byte1 | byte2 | byte3 | byte4 | byte5 | byte6 | byte7 | byte8) // 64bits
                maskRange = 10 ..< 14
            } else {
                payloadLength = UInt64(lengthIndicator) // 8bits
                maskRange = 2 ..< 6
            }
            let mask = Data(data[maskRange])
            guard let opCode = FrameHeader.OpCode(rawValue: opCodeRaw) else { fatalError("Unexpected opcode value: \(opCodeRaw)") }
            let header = FrameHeader(final: final, opCode: opCode, payloadLength: payloadLength, mask: mask)
            return process(header: header, data: data[maskRange.endIndex...])
        case .receivingPayload(frameHeader: let header, partialPayload: let partialPayload):
            return process(header: header, data: data, partialPayload: partialPayload)
        }
    }
    
    private func process(header: FrameHeader, data: Data, partialPayload: Data = Data()) -> Frame? {
        let payload = partialPayload + data.enumerated().map { $0.element ^ Data(header.mask)[($0.offset + partialPayload.count) % 4] }
        if payload.count == header.payloadLength {
            stage = .receivingInfo
            switch header.opCode {
            case .cont:
                return .cont
            case .text:
                return .text(String(data: payload, encoding: .utf8)!)
            case .binary:
                return .binary(payload)
            case .close:
                if let code = payload.closeCode {
                    return .close(.init(code: code, reason: payload.closeReason))
                }
                return .close(nil)
            case .ping:
                return .ping(payload)
            case .pong:
                return .pong(payload)
            }
        } else {
            stage = .receivingPayload(frameHeader: header, partialPayload: payload)
            return nil
        }
    }
}

extension Data {
    
    var closeCode: UInt16? {
        guard count >= 2 else { return nil }
        return UInt16(UInt16(self[0]) << 8 | UInt16(self[1]))
    }
    
    var closeReason: Data? {
        guard count > 2 else { return nil }
        return self[2...]
    }
}
