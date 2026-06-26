#import <Cocoa/Cocoa.h>

@class HALConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface HALBootViewController : NSViewController

- (instancetype)initWithConfiguration:(HALConfiguration *)configuration
                           completion:(void (^)(void))completion;

- (void)start;
- (void)skip;

@end

NS_ASSUME_NONNULL_END
