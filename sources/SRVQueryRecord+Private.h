//
//  SRVQueryRecord+Private.h
//  srvresolver
//

#import <Foundation/Foundation.h>

@interface SRVQueryRecord(Private)

- (instancetype)initFrom:(const void *)rdata rlen:(uint16_t)rlen ttl:(uint32_t)ttl;

@end
