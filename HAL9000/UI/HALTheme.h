#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface HALTheme : NSObject
+ (NSColor *)background;
+ (NSColor *)panel;
+ (NSColor *)line;
+ (NSColor *)text;
+ (NSColor *)secondaryText;
+ (NSColor *)halRed;
+ (NSColor *)dimRed;
+ (NSColor *)warning;
+ (NSColor *)listening;
+ (NSColor *)success;
+ (NSColor *)colorFromHex:(NSString *)hex;
+ (NSString *)hexFromColor:(NSColor *)color;
+ (NSFont *)uiFontOfSize:(CGFloat)size weight:(NSFontWeight)weight;
+ (NSFont *)monoFontOfSize:(CGFloat)size weight:(NSFontWeight)weight;
@end

NS_ASSUME_NONNULL_END
