#import <Cocoa/Cocoa.h>

@class HALConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface HALMainWindowController : NSWindowController

- (instancetype)initWithConfiguration:(HALConfiguration *)configuration
                contentViewController:(NSViewController *)contentViewController;

- (void)applyConfiguration:(HALConfiguration *)configuration;

@end

NS_ASSUME_NONNULL_END
