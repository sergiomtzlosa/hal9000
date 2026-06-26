#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HALLaunchAtLogin : NSObject

+ (instancetype)sharedController;

- (BOOL)isEnabled;
- (BOOL)setEnabled:(BOOL)enabled error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
