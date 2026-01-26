#import "HALTheme.h"

@implementation HALTheme

+ (NSColor *)colorFromHex:(NSString *)hex {
    NSString *clean = [hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    clean = [clean stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if (clean.length == 3) {
        clean = [NSString stringWithFormat:@"%c%c%c%c%c%c",
                 [clean characterAtIndex:0], [clean characterAtIndex:0],
                 [clean characterAtIndex:1], [clean characterAtIndex:1],
                 [clean characterAtIndex:2], [clean characterAtIndex:2]];
    }
    if (clean.length != 6) {
        return [self halRed];
    }
    unsigned int value = 0;
    if (![[NSScanner scannerWithString:clean] scanHexInt:&value]) {
        return [self halRed];
    }
    return [NSColor colorWithSRGBRed:((value >> 16) & 0xFF) / 255.0
                               green:((value >> 8) & 0xFF) / 255.0
                                blue:(value & 0xFF) / 255.0
                               alpha:1.0];
}

+ (NSString *)hexFromColor:(NSColor *)color {
    NSColor *rgb = [color colorUsingColorSpace:[NSColorSpace sRGBColorSpace]] ?: color;
    return [NSString stringWithFormat:@"#%02X%02X%02X",
            (int)lround(rgb.redComponent * 255.0),
            (int)lround(rgb.greenComponent * 255.0),
            (int)lround(rgb.blueComponent * 255.0)];
}

+ (NSColor *)background { return [self colorFromHex:@"#050607"]; }
+ (NSColor *)panel { return [self colorFromHex:@"#0B0D0F"]; }
+ (NSColor *)line { return [self colorFromHex:@"#1C2326"]; }
+ (NSColor *)text { return [self colorFromHex:@"#E8E8E6"]; }
+ (NSColor *)secondaryText { return [self colorFromHex:@"#899296"]; }
+ (NSColor *)halRed { return [self colorFromHex:@"#FF2A1A"]; }
+ (NSColor *)dimRed { return [self colorFromHex:@"#7A0F08"]; }
+ (NSColor *)warning { return [self colorFromHex:@"#FFB020"]; }
+ (NSColor *)listening { return [self colorFromHex:@"#6FD6FF"]; }
+ (NSColor *)success { return [self colorFromHex:@"#67D391"]; }

+ (NSFont *)uiFontOfSize:(CGFloat)size weight:(NSFontWeight)weight {
    return [NSFont systemFontOfSize:size weight:weight];
}

+ (NSFont *)monoFontOfSize:(CGFloat)size weight:(NSFontWeight)weight {
    return [NSFont monospacedSystemFontOfSize:size weight:weight];
}

@end
