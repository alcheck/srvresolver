//
//  SRVQueryRecord.m
//  srvresolver
//

#import "SRVQueryRecord.h"
#import "SRVQueryRecord+Private.h"
#import "dns_util.h"
#import <dns_sd.h>

// dns header for parsing record_t
struct _RecordParseHeader {
    uint8_t version;
    uint16_t rType;
    uint16_t rClass;
    uint32_t m;
    uint16_t rDataLen;
} __attribute__((packed));

typedef struct _RecordParseHeader RecordParseHeader;

@implementation SRVQueryRecord

- (instancetype)initFrom:(const void *)rdata rlen:(uint16_t)rlen ttl:(uint32_t)ttl {
    size_t dataSz = sizeof(RecordParseHeader) + rlen;
    uint8_t p[dataSz];

    RecordParseHeader header = { 0, htons(kDNSServiceType_SRV), htons(kDNSServiceClass_IN), htonl(666), htons(rlen) };
    *((RecordParseHeader *)p) = header;
    
    memcpy(p + sizeof(RecordParseHeader), rdata, rlen);

    dns_resource_record_t *rec = dns_parse_resource_record((const char *)p, (uint32_t)dataSz);
    
    if (!rec) return nil;
    
    dns_SRV_record_t *srv = rec->data.SRV;
    
    if (!srv) {
        dns_free_resource_record(rec);
        return nil;
    }
    
    if (self = [super init]) {
        self.port = srv->port;
        self.weight = srv->weight;
        self.priority = srv->priority;
        self.ttl = ttl;
        self.target = [NSString stringWithCString:srv->target encoding:NSUTF8StringEncoding];
        dns_free_resource_record(rec);
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"SRV_IN { '%@: %ld', w: %ld, p: %ld, ttl: %ld }", self.target, (long)self.port, (long)self.weight, self.priority, self.ttl];
}

@end
