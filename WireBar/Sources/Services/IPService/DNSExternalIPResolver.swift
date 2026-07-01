import Foundation
import Network

struct DNSExternalIPResolver: ExternalIPResolving {
    func fetchExternalIP() async throws -> String {
        do {
            return try await queryCloudflare()
        } catch {
            return try await queryOpenDNS()
        }
    }

    private func queryCloudflare() async throws -> String {
        let response = try await sendDNSQuery(
            server: "1.1.1.1",
            domain: "whoami.cloudflare",
            recordType: 16 // TXT
        )
        return try parseTXTResponse(response)
    }

    private func queryOpenDNS() async throws -> String {
        let response = try await sendDNSQuery(
            server: "208.67.222.222",
            domain: "myip.opendns.com",
            recordType: 1 // A
        )
        return try parseAResponse(response)
    }

    private func sendDNSQuery(server: String, domain: String, recordType: UInt16) async throws -> Data {
        let query = buildDNSQuery(domain: domain, recordType: recordType)

        let host = NWEndpoint.Host(server)
        let port = NWEndpoint.Port(integerLiteral: 53)
        let connection = NWConnection(host: host, port: port, using: .udp)

        return try await withCheckedThrowingContinuation { continuation in
            let gate = ContinuationGate(continuation: continuation, connection: connection)

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    connection.send(content: query, completion: .contentProcessed { error in
                        if let error {
                            gate.resume(with: .failure(error))
                            return
                        }
                        connection.receive(minimumIncompleteLength: 1, maximumLength: 512) { data, _, _, recvError in
                            if let error = recvError {
                                gate.resume(with: .failure(error))
                            } else if let data {
                                gate.resume(with: .success(data))
                            } else {
                                gate.resume(with: .failure(DNSError.emptyResponse))
                            }
                        }
                    })
                case .failed(let error):
                    gate.resume(with: .failure(error))
                case .cancelled:
                    gate.resume(with: .failure(DNSError.cancelled))
                default:
                    break
                }
            }

            connection.start(queue: .global())

            DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                gate.resume(with: .failure(DNSError.timeout))
            }
        }
    }

    private func buildDNSQuery(domain: String, recordType: UInt16) -> Data {
        var data = Data()

        // Header
        let id: UInt16 = UInt16.random(in: 0...UInt16.max)
        data.append(contentsOf: withUnsafeBytes(of: id.bigEndian) { Array($0) })
        data.append(contentsOf: [0x01, 0x00]) // Flags: standard query, recursion desired
        data.append(contentsOf: [0x00, 0x01]) // QDCOUNT: 1 question
        data.append(contentsOf: [0x00, 0x00]) // ANCOUNT: 0
        data.append(contentsOf: [0x00, 0x00]) // NSCOUNT: 0
        data.append(contentsOf: [0x00, 0x00]) // ARCOUNT: 0

        // Question: encode domain name
        for label in domain.split(separator: ".") {
            data.append(UInt8(label.count))
            data.append(contentsOf: label.utf8)
        }
        data.append(0x00) // Root label

        // Type and Class
        data.append(contentsOf: withUnsafeBytes(of: recordType.bigEndian) { Array($0) })
        data.append(contentsOf: [0x00, 0x01]) // Class: IN

        return data
    }

    private func parseTXTResponse(_ data: Data) throws -> String {
        guard data.count >= 12 else { throw DNSError.malformedResponse }

        let answerCount = UInt16(data[6]) << 8 | UInt16(data[7])
        guard answerCount > 0 else { throw DNSError.noAnswers }

        var offset = 12
        // Skip the question section
        offset = try skipDNSName(in: data, at: offset)
        offset += 4 // Skip QTYPE + QCLASS

        // Parse first answer
        offset = try skipDNSName(in: data, at: offset)
        guard offset + 10 <= data.count else { throw DNSError.malformedResponse }

        offset += 2 // TYPE
        offset += 2 // CLASS
        offset += 4 // TTL

        let rdLength = Int(UInt16(data[offset]) << 8 | UInt16(data[offset + 1]))
        offset += 2

        guard offset + rdLength <= data.count else { throw DNSError.malformedResponse }

        // TXT RDATA: first byte is string length, followed by the string
        guard rdLength > 1 else { throw DNSError.malformedResponse }
        let txtLength = Int(data[offset])
        offset += 1

        guard offset + txtLength <= data.count else { throw DNSError.malformedResponse }
        guard let ip = String(data: data[offset..<(offset + txtLength)], encoding: .utf8) else {
            throw DNSError.malformedResponse
        }

        guard isValidIPv4(ip) else { throw DNSError.invalidIP }
        return ip
    }

    private func parseAResponse(_ data: Data) throws -> String {
        guard data.count >= 12 else { throw DNSError.malformedResponse }

        let answerCount = UInt16(data[6]) << 8 | UInt16(data[7])
        guard answerCount > 0 else { throw DNSError.noAnswers }

        var offset = 12
        offset = try skipDNSName(in: data, at: offset)
        offset += 4 // QTYPE + QCLASS

        // Parse first answer
        offset = try skipDNSName(in: data, at: offset)
        guard offset + 10 <= data.count else { throw DNSError.malformedResponse }

        offset += 2 // TYPE
        offset += 2 // CLASS
        offset += 4 // TTL

        let rdLength = Int(UInt16(data[offset]) << 8 | UInt16(data[offset + 1]))
        offset += 2

        guard rdLength == 4, offset + 4 <= data.count else { throw DNSError.malformedResponse }

        let ip = "\(data[offset]).\(data[offset+1]).\(data[offset+2]).\(data[offset+3])"
        return ip
    }

    private func skipDNSName(in data: Data, at startOffset: Int) throws -> Int {
        var offset = startOffset
        while offset < data.count {
            let labelLength = data[offset]
            if labelLength == 0 {
                return offset + 1
            }
            // Compression pointer
            if labelLength & 0xC0 == 0xC0 {
                return offset + 2
            }
            offset += Int(labelLength) + 1
        }
        throw DNSError.malformedResponse
    }

    private func isValidIPv4(_ string: String) -> Bool {
        let parts = string.split(separator: ".")
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            guard let num = UInt8(part) else { return false }
            return num <= 255
        }
    }
}

enum DNSError: Error {
    case emptyResponse
    case malformedResponse
    case noAnswers
    case invalidIP
    case timeout
    case cancelled
}

private final class ContinuationGate: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Data, Error>?
    private let connection: NWConnection

    init(continuation: CheckedContinuation<Data, Error>, connection: NWConnection) {
        self.continuation = continuation
        self.connection = connection
    }

    func resume(with result: Result<Data, Error>) {
        lock.lock()
        let cont = continuation
        continuation = nil
        lock.unlock()

        if let cont {
            connection.cancel()
            cont.resume(with: result)
        }
    }
}
