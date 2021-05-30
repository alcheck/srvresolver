//
//  SRVQueryRecord.h
//  srvresolver
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRVQueryRecord : NSObject

@property(nonatomic) NSString *target;
@property(nonatomic) NSInteger weight;
@property(nonatomic) NSInteger priority;
@property(nonatomic) NSInteger port;
@property(nonatomic) NSInteger ttl;

@end

NS_ASSUME_NONNULL_END
