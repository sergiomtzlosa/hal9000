#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HALHotKeyManager : NSObject

@property (nonatomic, copy, nullable) void (^onHotKey)(void);

- (BOOL)registerHotKey;
- (void)unregisterHotKey;

@end

NS_ASSUME_NONNULL_END
