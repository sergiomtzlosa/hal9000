#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HALSSEParser : NSObject

- (NSArray<NSDictionary<NSString *, id> *> *)appendData:(NSData *)data;
- (void)reset;

@end

NS_ASSUME_NONNULL_END
