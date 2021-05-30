//
//  DNSQueryResolver.swift
//  link with: libresolv
//

import Foundation
import dnssd
import srvresolver.dnsutil

fileprivate extension UInt16 {
    static let dnsTypeSRV = Self(kDNSServiceType_SRV)
    static let dnsClassIN = Self(kDNSServiceClass_IN)
}

public enum DNSQueryError: Error, Equatable {
    case timeout
    case general(reason: String)
}

/**
 Holds the result of SRV_IN DNS request
 */
public struct SRVQueryRecord: CustomStringConvertible, Hashable {
    public let target: String
    public let weight: Int
    public let priority: Int
    public let port: Int
    public let ttl: Int
    
    public var description: String {
        "SRV_IN { '\(target):\(port)', weight: \(weight), priority: \(priority), ttl: \(ttl) }"
    }
}

fileprivate extension RecordParseHeader {
    static func srvHeader(for len: Int) -> Self {
        Self(version: 0,
             rType: UInt16.dnsTypeSRV.bigEndian,
             rClass: UInt16.dnsClassIN.bigEndian,
             m: UInt32(666).bigEndian,
             rDataLen: UInt16(len).bigEndian)
    }
}

fileprivate extension SRVQueryRecord {
    init?(rdata: UnsafeRawPointer, rlen: Int, ttl: UInt32) {
        let headerSize = MemoryLayout<RecordParseHeader>.size
        let dataSize = headerSize + rlen
        
        let p = UnsafeMutableRawPointer.allocate(byteCount: dataSize, alignment: 1)
        defer { p.deallocate() }
        
        p.storeBytes(of: RecordParseHeader.srvHeader(for: rlen), as: RecordParseHeader.self)
        (p + headerSize).copyMemory(from: rdata, byteCount: rlen)
        
        let record_t = dns_parse_resource_record(p.bindMemory(to: Int8.self, capacity: dataSize), UInt32(dataSize))
        
        guard let srv = record_t?.pointee.data.SRV.pointee else { return nil }
        
        self.port = Int(srv.port)
        self.weight = Int(srv.weight)
        self.priority = Int(srv.priority)
        self.ttl = Int(ttl)
        self.target = String(cString: srv.target)
        
        dns_free_resource_record(record_t)
    }
    
    static func sort(_ records: [Self]) -> [Self] {
        records.sorted {
            if $0.priority < $1.priority { return true }
            else if $0.priority == $1.priority { return $0.weight > $1.weight }
            return false
        }
    }
}

public final class DNSQueryResolver {
    public typealias QueryHandler = ([SRVQueryRecord], DNSQueryError?) -> Void
    
    private var sdRef: DNSServiceRef?
    private var socketRef: CFSocket?
    private var records: [SRVQueryRecord] = []
    private var completion: QueryHandler?
    private var watchdogTimer: Timer?
    
    public static func start(_ srv: String, timeout: TimeInterval, completion: @escaping QueryHandler) {
        OperationQueue.main.addOperation {
            DNSQueryResolver().start(srv, timeout: timeout, completion: completion)
        }
    }
        
    private func start(_ srv: String, timeout: TimeInterval, completion: @escaping QueryHandler) {
        self.completion = completion
        
        let ctx = Unmanaged.passUnretained(self).toOpaque()
        var sctx = CFSocketContext(version: 0, info: ctx, retain: nil, release: nil, copyDescription: nil)
        
        guard kDNSServiceErr_NoError == DNSServiceQueryRecord(&sdRef, 0, 0, srv, .dnsTypeSRV, .dnsClassIN, Self.replyHandler, ctx) else {
            finish(err: .general(reason: "Failed to initialize query"))
            return
        }
        
        let fd = DNSServiceRefSockFD(sdRef)
        let socket = CFSocketCreateWithNative(nil, fd, CFSocketCallBackType.readCallBack.rawValue, Self.socketHandler, &sctx)
        
        CFSocketSetSocketFlags(socket, CFSocketGetSocketFlags(socket) & ~kCFSocketCloseOnInvalidate)
        
        let rls = CFSocketCreateRunLoopSource(nil, socket, 0)
        guard rls != nil else {
            finish(err: .general(reason: "Failed to create socket runloop source"))
            return
        }

        CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, .defaultMode)
        self.socketRef = socket
        
        // watchdog timer retains 'self' till it fired or invalidated
        self.watchdogTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { _ in
            self.finish(err: .timeout)
        }
    }
    
    private func cleanup() {
        if socketRef != nil {
            CFSocketInvalidate(socketRef)
            socketRef = nil
        }
        
        if sdRef != nil {
            DNSServiceRefDeallocate(sdRef)
            sdRef = nil
        }
        
        watchdogTimer?.invalidate()
        watchdogTimer = nil
    }
    
    deinit {
        cleanup()
    }
    
    private func finish(err: DNSQueryError?) {
        cleanup()
        completion?(SRVQueryRecord.sort(records), err)
    }
    
    private static let socketHandler: CFSocketCallBack = { _, _, _, _, info in
        guard let info = info else {
            assert(false, "[DNSQueryResolver] failed to get context info in socket handler")
            return
        }
        
        let resolver = Unmanaged<DNSQueryResolver>.fromOpaque(info).takeUnretainedValue()
        if DNSServiceProcessResult(resolver.sdRef) != kDNSServiceErr_NoError {
            resolver.finish(err: .general(reason: "Failed to start process result"))
        }
    }
    
    private static let replyHandler: DNSServiceQueryRecordReply = { _, flags, _, err, _, type, cls, len, rdata, ttl, ctx in
        guard let ctx = ctx else {
            assert(false, "[DNSQueryResolver] failed tot get context in dns query handler")
            return
        }
        
        let resolver = Unmanaged<DNSQueryResolver>.fromOpaque(ctx).takeUnretainedValue()
        
        guard err == kDNSServiceErr_NoError, type == .dnsTypeSRV, cls == .dnsClassIN, let rdata = rdata else {
            resolver.finish(err: .general(reason: "Error detected while enumerating"))
            return
        }
        
        if let record = SRVQueryRecord(rdata: rdata, rlen: Int(len), ttl: ttl) {
            resolver.records.append(record)
        } else {
            resolver.finish(err: .general(reason: "Failed to parse resource record from rdata"))
        }
        
        if (flags & kDNSServiceFlagsMoreComing) == 0 {
            resolver.finish(err: nil)
        }
    }
}
