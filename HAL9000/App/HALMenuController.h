#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface HALMenuController : NSObject

- (void)installMainMenuWithTarget:(id)target;
- (void)updateListening:(BOOL)listening muted:(BOOL)muted;

@end

NS_ASSUME_NONNULL_END
