#import "HALCinemaWindowController.h"
#import "HALConfiguration.h"
#import "HALTheme.h"

@interface HALCinemaWindow : NSWindow
@property (nonatomic, copy, nullable) void (^onEscape)(void);
@end

@implementation HALCinemaWindow
- (BOOL)canBecomeKeyWindow { return YES; }
- (BOOL)canBecomeMainWindow { return YES; }
- (void)keyDown:(NSEvent *)event {
    if (event.keyCode == 53) {
        if (self.onEscape) self.onEscape();
        return;
    }
    [super keyDown:event];
}
- (void)cancelOperation:(id)sender {
    if (self.onEscape) self.onEscape();
}
@end

@interface HALCinemaWindowController () <NSWindowDelegate>
@property (nonatomic, strong) HALConfiguration *configuration;
@property (nonatomic, strong) HALEyeView *eyeView;
@property (nonatomic, strong) NSTextField *subtitleLabel;
@property (nonatomic, strong) NSTextField *statusLabel;
@property (nonatomic, assign) BOOL didNotifyClose;
@end

@implementation HALCinemaWindowController

- (instancetype)initWithConfiguration:(HALConfiguration *)configuration {
    HALCinemaWindow *window = [[HALCinemaWindow alloc] initWithContentRect:NSMakeRect(0, 0, 1200, 800)
                                                                 styleMask:NSWindowStyleMaskBorderless
                                                                   backing:NSBackingStoreBuffered
                                                                     defer:NO];
    window.backgroundColor = [NSColor blackColor];
    window.opaque = YES;
    window.hasShadow = NO;
    window.releasedWhenClosed = NO;
    window.collectionBehavior = NSWindowCollectionBehaviorFullScreenAuxiliary;
    window.delegate = self;
    self = [super initWithWindow:window];
    if (self) {
        _configuration = configuration;
        __weak typeof(self) weakSelf = self;
        window.onEscape = ^{
            [weakSelf closeCinema];
        };
        [self buildInterface];
    }
    return self;
}

- (void)buildInterface {
    NSView *root = self.window.contentView;
    root.wantsLayer = YES;
    root.layer.backgroundColor = [NSColor blackColor].CGColor;

    self.eyeView = [[HALEyeView alloc] initWithFrame:NSZeroRect];
    self.eyeView.translatesAutoresizingMaskIntoConstraints = NO;
    __weak typeof(self) weakSelf = self;
    self.eyeView.onClick = ^{
        if (weakSelf.onToggleListening) weakSelf.onToggleListening();
    };
    [root addSubview:self.eyeView];

    NSTextField *title = [NSTextField labelWithString:@"HAL 9000 · CINEMA"];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.font = [HALTheme monoFontOfSize:10 weight:NSFontWeightMedium];
    title.textColor = [HALTheme secondaryText];
    [root addSubview:title];

    self.statusLabel = [NSTextField labelWithString:@"STANDBY"];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.font = [HALTheme monoFontOfSize:9 weight:NSFontWeightMedium];
    self.statusLabel.textColor = [HALTheme secondaryText];
    self.statusLabel.alignment = NSTextAlignmentRight;
    [root addSubview:self.statusLabel];

    self.subtitleLabel = [NSTextField wrappingLabelWithString:@""];
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.subtitleLabel.font = [HALTheme uiFontOfSize:22 weight:NSFontWeightLight];
    self.subtitleLabel.textColor = [HALTheme text];
    self.subtitleLabel.alignment = NSTextAlignmentCenter;
    self.subtitleLabel.maximumNumberOfLines = 3;
    self.subtitleLabel.preferredMaxLayoutWidth = 900;
    [root addSubview:self.subtitleLabel];

    NSButton *exit = [[NSButton alloc] initWithFrame:NSZeroRect];
    exit.translatesAutoresizingMaskIntoConstraints = NO;
    exit.bordered = NO;
    exit.target = self;
    exit.action = @selector(exitPressed:);
    exit.attributedTitle = [[NSAttributedString alloc] initWithString:@"EXIT CINEMA  ESC" attributes:@{
        NSFontAttributeName: [HALTheme monoFontOfSize:9 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName: [HALTheme secondaryText]
    }];
    [root addSubview:exit];

    NSTextField *hint = [NSTextField labelWithString:@"CLICK THE EYE OR PRESS ⌥SPACE TO SPEAK"];
    hint.translatesAutoresizingMaskIntoConstraints = NO;
    hint.font = [HALTheme monoFontOfSize:8 weight:NSFontWeightMedium];
    hint.textColor = [[HALTheme secondaryText] colorWithAlphaComponent:0.55];
    [root addSubview:hint];

    [NSLayoutConstraint activateConstraints:@[
        [self.eyeView.centerXAnchor constraintEqualToAnchor:root.centerXAnchor],
        [self.eyeView.centerYAnchor constraintEqualToAnchor:root.centerYAnchor constant:-30],
        [self.eyeView.widthAnchor constraintEqualToConstant:500],
        [self.eyeView.heightAnchor constraintEqualToConstant:500],

        [title.leadingAnchor constraintEqualToAnchor:root.leadingAnchor constant:28],
        [title.topAnchor constraintEqualToAnchor:root.topAnchor constant:24],

        [self.statusLabel.trailingAnchor constraintEqualToAnchor:root.trailingAnchor constant:-28],
        [self.statusLabel.topAnchor constraintEqualToAnchor:root.topAnchor constant:24],

        [exit.trailingAnchor constraintEqualToAnchor:root.trailingAnchor constant:-28],
        [exit.topAnchor constraintEqualToAnchor:root.topAnchor constant:54],

        [self.subtitleLabel.leadingAnchor constraintEqualToAnchor:root.leadingAnchor constant:60],
        [self.subtitleLabel.trailingAnchor constraintEqualToAnchor:root.trailingAnchor constant:-60],
        [self.subtitleLabel.bottomAnchor constraintEqualToAnchor:root.bottomAnchor constant:-92],

        [hint.centerXAnchor constraintEqualToAnchor:root.centerXAnchor],
        [hint.bottomAnchor constraintEqualToAnchor:root.bottomAnchor constant:-30]
    ]];
    [self refreshAppearance];
}

- (void)refreshAppearance {
    self.eyeView.eyeColor = [HALTheme colorFromHex:self.configuration.eyeColorHex];
    self.eyeView.glowIntensity = self.configuration.glowIntensity;
    self.eyeView.pulseSpeed = self.configuration.pulseSpeed;
    self.eyeView.eyeScale = self.configuration.eyeScale;
    self.eyeView.scanlinesEnabled = self.configuration.scanlines;
    self.eyeView.grainEnabled = self.configuration.grain;
    self.eyeView.trackCursorEnabled = self.configuration.trackCursor;
    self.eyeView.blinkEnabled = self.configuration.blinkEnabled;
    self.eyeView.blinkInterval = self.configuration.blinkInterval;
    self.subtitleLabel.hidden = !self.configuration.showSubtitles;
    BOOL systemReduce = [NSWorkspace sharedWorkspace].accessibilityDisplayShouldReduceMotion;
    if ([self.configuration.reduceMotionMode isEqualToString:@"on"]) self.eyeView.reduceMotion = YES;
    else if ([self.configuration.reduceMotionMode isEqualToString:@"off"]) self.eyeView.reduceMotion = NO;
    else self.eyeView.reduceMotion = systemReduce;
}

- (void)setEyeState:(HALEyeState)state {
    [self.eyeView setState:state animated:YES];
}

- (void)setSubtitle:(NSString *)subtitle {
    self.subtitleLabel.stringValue = subtitle ?: @"";
}

- (void)setStatus:(NSString *)status {
    self.statusLabel.stringValue = status.uppercaseString;
}

- (void)showCinema {
    self.didNotifyClose = NO;
    NSScreen *screen = [NSScreen mainScreen];
    if (screen) [self.window setFrame:screen.frame display:YES];
    [self.window makeKeyAndOrderFront:nil];
    [self.window makeFirstResponder:self.window.contentView];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)closeCinema {
    [self.window close];
}

- (void)exitPressed:(id)sender {
    [self closeCinema];
}

- (void)windowWillClose:(NSNotification *)notification {
    if (self.didNotifyClose) return;
    self.didNotifyClose = YES;
    [self.eyeView setState:HALEyeStateIdle animated:NO];
    if (self.onClose) self.onClose();
}

@end
