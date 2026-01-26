#import "HALAboutWindowController.h"
#import "HALTheme.h"

@implementation HALAboutWindowController

- (instancetype)init {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 480, 390)
                                                   styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable)
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    window.title = @"About HAL 9000";
    window.backgroundColor = [HALTheme background];
    window.minSize = NSMakeSize(480, 390);
    window.maxSize = NSMakeSize(480, 390);
    self = [super initWithWindow:window];
    if (self) {
        [self buildInterface];
    }
    return self;
}

- (void)buildInterface {
    NSView *root = self.window.contentView;
    root.wantsLayer = YES;
    root.layer.backgroundColor = [HALTheme background].CGColor;

    NSImageView *icon = [[NSImageView alloc] initWithFrame:NSZeroRect];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.image = [NSApp applicationIconImage];
    icon.imageScaling = NSImageScaleProportionallyUpOrDown;
    [root addSubview:icon];

    NSTextField *title = [NSTextField labelWithString:@"HAL 9000"];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.font = [HALTheme uiFontOfSize:24 weight:NSFontWeightLight];
    title.textColor = [HALTheme text];
    title.alignment = NSTextAlignmentCenter;
    [root addSubview:title];

    NSTextField *subtitle = [NSTextField labelWithString:@"A FAN-MADE SIMULATION"];
    subtitle.translatesAutoresizingMaskIntoConstraints = NO;
    subtitle.font = [HALTheme monoFontOfSize:9 weight:NSFontWeightSemibold];
    subtitle.textColor = [HALTheme halRed];
    subtitle.alignment = NSTextAlignmentCenter;
    [root addSubview:subtitle];

    NSString *version = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"] ?: @"1.0";
    NSTextField *versionLabel = [NSTextField labelWithString:[NSString stringWithFormat:@"Version %@", version]];
    versionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    versionLabel.font = [HALTheme monoFontOfSize:9 weight:NSFontWeightRegular];
    versionLabel.textColor = [HALTheme secondaryText];
    versionLabel.alignment = NSTextAlignmentCenter;
    [root addSubview:versionLabel];

    NSTextField *body = [NSTextField wrappingLabelWithString:@"An offline-first control-room simulation with an original animated eye, a scripted personality, a simulated Discovery One, and optional local or OpenAI-compatible intelligence.\n\nOriginal code and artwork. Not affiliated with or endorsed by the rights holders of 2001: A Space Odyssey. Short iconic phrases are used descriptively."];
    body.translatesAutoresizingMaskIntoConstraints = NO;
    body.font = [HALTheme uiFontOfSize:11 weight:NSFontWeightRegular];
    body.textColor = [HALTheme secondaryText];
    body.alignment = NSTextAlignmentCenter;
    body.preferredMaxLayoutWidth = 380;
    [root addSubview:body];

    NSTextField *credit = [NSTextField labelWithString:@"MIT licensed · No telemetry · Audio never stored"];
    credit.translatesAutoresizingMaskIntoConstraints = NO;
    credit.font = [HALTheme monoFontOfSize:8 weight:NSFontWeightRegular];
    credit.textColor = [[HALTheme secondaryText] colorWithAlphaComponent:0.7];
    credit.alignment = NSTextAlignmentCenter;
    [root addSubview:credit];

    [NSLayoutConstraint activateConstraints:@[
        [icon.topAnchor constraintEqualToAnchor:root.topAnchor constant:28],
        [icon.centerXAnchor constraintEqualToAnchor:root.centerXAnchor],
        [icon.widthAnchor constraintEqualToConstant:112],
        [icon.heightAnchor constraintEqualToConstant:112],

        [title.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:16],
        [title.centerXAnchor constraintEqualToAnchor:root.centerXAnchor],

        [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:4],
        [subtitle.centerXAnchor constraintEqualToAnchor:root.centerXAnchor],

        [versionLabel.topAnchor constraintEqualToAnchor:subtitle.bottomAnchor constant:6],
        [versionLabel.centerXAnchor constraintEqualToAnchor:root.centerXAnchor],

        [body.topAnchor constraintEqualToAnchor:versionLabel.bottomAnchor constant:18],
        [body.leadingAnchor constraintEqualToAnchor:root.leadingAnchor constant:48],
        [body.trailingAnchor constraintEqualToAnchor:root.trailingAnchor constant:-48],

        [credit.bottomAnchor constraintEqualToAnchor:root.bottomAnchor constant:-22],
        [credit.centerXAnchor constraintEqualToAnchor:root.centerXAnchor]
    ]];
}

- (void)showAbout {
    [self showWindow:nil];
    [self.window center];
    [self.window makeKeyAndOrderFront:nil];
}

@end
