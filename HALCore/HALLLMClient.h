#import <Foundation/Foundation.h>

@class HALConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface HALLLMClient : NSObject

@property (nonatomic, strong, readonly) HALConfiguration *configuration;

- (instancetype)initWithConfiguration:(HALConfiguration *)configuration apiKey:(nullable NSString *)apiKey;

- (void)streamMessages:(NSArray<NSDictionary<NSString *, id> *> *)messages
               onDelta:(void (^)(NSString *delta))onDelta
            completion:(void (^)(NSError * _Nullable error))completion;
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
