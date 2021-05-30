//
//  SRVQueryResolver.h
//  srvresolver
//

#import <Foundation/Foundation.h>
#import "SRVQueryRecord.h"

typedef void (^SRVQueryHandler)(NSArray<SRVQueryRecord*> *_Nullable, NSError *_Nullable);

NS_ASSUME_NONNULL_BEGIN

@interface SRVQueryResolver : NSObject

+ (void)query:(NSString *)service timeout:(NSTimeInterval)timeout completion:(SRVQueryHandler)handler;

@end

NS_ASSUME_NONNULL_END
