//
//  SRVQueryResolver.m
//  srvresolver
//

#import "SRVQueryResolver.h"
#import "SRVQueryRecord+Private.h"

@import dnssd;

@implementation SRVQueryResolver {
    DNSServiceRef sdRef;
    CFSocketRef socket;
    NSMutableArray<SRVQueryRecord*> *records;
    SRVQueryHandler completionHandler;
    NSTimer *watchDogTimer;
}

+ (void)query:(NSString *)service timeout:(NSTimeInterval)timeout completion:(SRVQueryHandler)handler {
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
        [[self new] startFor:service timeout:timeout completion:handler];
    }];
}

- (void)startFor:(NSString *)service timeout:(NSTimeInterval)timeout completion:(SRVQueryHandler)handler {
    completionHandler = handler;
    
    void *ctx = (__bridge void *)self;
    CFSocketContext sctx = { 0, ctx, NULL, NULL, NULL };
    
    if (kDNSServiceErr_NoError != DNSServiceQueryRecord(&sdRef, 0, 0, service.UTF8String, kDNSServiceType_SRV, kDNSServiceClass_IN, recordsQueryCallback, ctx)) {
        [self finishWithErrorString:@"Failed to init query"];
        return;
    }
    
    dnssd_sock_t fd = DNSServiceRefSockFD(sdRef);
    socket = CFSocketCreateWithNative(NULL, fd, kCFSocketReadCallBack, socketCallback, &sctx);
    
    CFSocketSetSocketFlags(socket, CFSocketGetSocketFlags(socket) & ~kCFSocketCloseOnInvalidate);
    
    CFRunLoopSourceRef rls = CFSocketCreateRunLoopSource(NULL, socket, 0);
    
    if (!rls) {
        [self finishWithErrorString:@"Failed to create socket runloop source"];
        return;
    }
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
    
    watchDogTimer = [NSTimer scheduledTimerWithTimeInterval:timeout repeats:NO block:^(NSTimer *timer) {
        [self finishWithErrorString:@"Timeout reached"];
    }];
}

- (void)append:(SRVQueryRecord *)record {
    if (!records) {
        records = [NSMutableArray array];
    }
    
    [records addObject:record];
}

- (void)cleanup {
    if (socket) {
        CFSocketInvalidate(socket);
        socket = nil;
    }
    
    if (sdRef) {
        DNSServiceRefDeallocate(sdRef);
        sdRef = NULL;
    }

    [watchDogTimer invalidate];
}

- (void)dealloc {
    [self cleanup];
    
    #if DEBUG
        NSLog(@"%s", __PRETTY_FUNCTION__);
    #endif
}

- (void)finishWithErrorString:(nullable NSString *)errString {
    [self cleanup];
    
    NSError *err = nil;

    if (errString) {
        err = [NSError errorWithDomain:errString code:0 userInfo:nil];
    }
    
    if (completionHandler) {
        // need to add sort for records
        completionHandler(records, err);
    }
}

// MARK: - C callbacks

void socketCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef addr, const void *data, void *info) {
    SRVQueryResolver *self = (__bridge SRVQueryResolver*)info;

    if (DNSServiceProcessResult(self->sdRef) != kDNSServiceErr_NoError) {
        [self finishWithErrorString:@"Failed to start process result"];
    }
}

void recordsQueryCallback(DNSServiceRef sdRef, DNSServiceFlags flags, uint32_t idx, DNSServiceErrorType err, const char *fullname, uint16_t rrtype, uint16_t rrclass, uint16_t rdlen, const void *rdata, uint32_t ttl, void *ctx) {
    
    SRVQueryResolver *self = (__bridge SRVQueryResolver*)ctx;
    
    if (err != kDNSServiceErr_NoError || rrtype != kDNSServiceType_SRV || rrclass != kDNSServiceClass_IN || rdata == NULL) {
        [self finishWithErrorString:@"Error detected while enumerating"];
        return;
    }
    
    SRVQueryRecord *record = [[SRVQueryRecord alloc] initFrom:rdata rlen:rdlen ttl:ttl];
    
    if (record) {
        [self append:record];
    } else {
        [self finishWithErrorString:@"Failed to parse resource record from rdata"];
    }
    
    if (!(flags & kDNSServiceFlagsMoreComing)) {
        [self finishWithErrorString:nil];
    }
}

@end

