#import <Cocoa/Cocoa.h>

@class HALConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface HAL3DViewerWindowController : NSWindowController

- (instancetype)initWithConfiguration:(HALConfiguration *)configuration;
- (void)refreshConfiguration;

@end

NS_ASSUME_NONNULL_END
