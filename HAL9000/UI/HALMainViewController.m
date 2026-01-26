#import "HALMainViewController.h"
#import "HALTheme.h"

@interface HALMainViewController ()
@property (nonatomic, strong) HALConfiguration *configuration;
@property (nonatomic, strong) HALShipSimulator *simulator;
@property (nonatomic, strong, readwrite) HALEyeView *eyeView;
@property (nonatomic, strong, readwrite) HALChatViewController *chatViewController;
@property (nonatomic, strong, readwrite) HALStatusSidebarViewController *sidebarViewController;
@property (nonatomic, strong) NSTextField *statusLabel;
@property (nonatomic, strong) NSButton *micButton;
@property (nonatomic, strong) NSView *topBar;
@property (nonatomic, strong) NSView *eyePanel;
@property (nonatomic, strong) NSView *contentView;
@property (nonatomic, strong) NSView *mainColumn;
@property (nonatomic, strong) NSLayoutConstraint *sidebarWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *mainColumnTrailingConstraint;
@property (nonatomic, strong) NSLayoutConstraint *hiddenSidebarTrailingConstraint;
@property (nonatomic, strong) NSLayoutConstraint *eyeHeightConstraint;
@property (nonatomic, strong, nullable) NSArray<NSLayoutConstraint *> *normalConstraints;
@property (nonatomic, strong, nullable) NSArray<NSLayoutConstraint *> *compactConstraints;
@property (nonatomic, assign, readwrite) BOOL compactMode;
@property (nonatomic, assign, readwrite) BOOL sidebarVisible;
@property (nonatomic, assign) BOOL listening;
- (NSTextField *)labelWithString:(NSString *)string font:(NSFont *)font color:(NSColor *)color;
@end

@implementation HALMainViewController

- (instancetype)initWithConfiguration:(HALConfiguration *)configuration
                           simulator:(HALShipSimulator *)simulator {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _configuration = configuration;
        _simulator = simulator;
        _sidebarVisible = configuration.showTelemetry;
    }
    return self;
}

- (void)loadView {
    NSView *root = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 1040, 700)];
    root.wantsLayer = YES;
    root.layer.backgroundColor = [HALTheme background].CGColor;
    self.view = root;

    self.topBar = [[NSView alloc] initWithFrame:NSZeroRect];
    self.topBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.topBar.wantsLayer = YES;
    self.topBar.layer.backgroundColor = [HALTheme background].CGColor;
    self.topBar.layer.borderColor = [HALTheme line].CGColor;
    self.topBar.layer.borderWidth = 1.0;
    [root addSubview:self.topBar];

    NSTextField *title = [self labelWithString:@"HAL 9000" font:[HALTheme uiFontOfSize:13 weight:NSFontWeightSemibold] color:[HALTheme text]];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [self.topBar addSubview:title];

    NSView *redDot = [[NSView alloc] initWithFrame:NSZeroRect];
    redDot.translatesAutoresizingMaskIntoConstraints = NO;
    redDot.wantsLayer = YES;
    redDot.layer.backgroundColor = [HALTheme halRed].CGColor;
    redDot.layer.cornerRadius = 4.0;
    [self.topBar addSubview:redDot];

    self.statusLabel = [self labelWithString:@"ALL SYSTEMS NOMINAL" font:[HALTheme monoFontOfSize:9 weight:NSFontWeightMedium] color:[HALTheme secondaryText]];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.topBar addSubview:self.statusLabel];

    NSButton *settings = [self topBarButton:@"SETTINGS" action:@selector(settingsPressed:)];
    NSButton *cinema = [self topBarButton:@"CINEMA" action:@selector(cinemaPressed:)];
    NSButton *threeD = [self topBarButton:@"3D" action:@selector(threeDPressed:)];
    NSButton *sidebar = [self topBarButton:@"STATUS" action:@selector(sidebarPressed:)];
    NSButton *help = [self topBarButton:@"HELP" action:@selector(helpPressed:)];
    self.micButton = [self topBarButton:@"● LISTEN" action:@selector(micPressed:)];
    [self.topBar addSubview:settings];
    [self.topBar addSubview:cinema];
    [self.topBar addSubview:threeD];
    [self.topBar addSubview:sidebar];
    [self.topBar addSubview:help];
    [self.topBar addSubview:self.micButton];

    self.contentView = [[NSView alloc] initWithFrame:NSZeroRect];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:self.contentView];

    self.mainColumn = [[NSView alloc] initWithFrame:NSZeroRect];
    self.mainColumn.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.mainColumn];

    self.sidebarViewController = [[HALStatusSidebarViewController alloc] initWithNibName:nil bundle:nil];
    self.sidebarViewController.simulator = self.simulator;
    self.sidebarViewController.configuration = self.configuration;
    __weak typeof(self) weakSelf = self;
    self.sidebarViewController.onScenarioChanged = ^(NSString *identifier) {
        if (weakSelf.onScenarioChanged) weakSelf.onScenarioChanged(identifier);
    };
    self.sidebarViewController.onDiagnostics = ^{
        if (weakSelf.onDiagnostics) weakSelf.onDiagnostics();
    };
    self.sidebarViewController.onOpen3D = ^{
        if (weakSelf.onOpen3D) weakSelf.onOpen3D();
    };
    [self addChildViewController:self.sidebarViewController];
    self.sidebarViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.sidebarViewController.view];

    self.eyePanel = [[NSView alloc] initWithFrame:NSZeroRect];
    self.eyePanel.translatesAutoresizingMaskIntoConstraints = NO;
    self.eyePanel.wantsLayer = YES;
    self.eyePanel.layer.backgroundColor = [HALTheme colorFromHex:@"#08090B"].CGColor;
    self.eyePanel.layer.borderColor = [HALTheme line].CGColor;
    self.eyePanel.layer.borderWidth = 1.0;
    [self.mainColumn addSubview:self.eyePanel];

    self.eyeView = [[HALEyeView alloc] initWithFrame:NSZeroRect];
    self.eyeView.translatesAutoresizingMaskIntoConstraints = NO;
    self.eyeView.onClick = ^{
        if (weakSelf.onToggleListening) weakSelf.onToggleListening();
    };
    [self.eyePanel addSubview:self.eyeView];

    NSTextField *eyeHint = [self labelWithString:@"CLICK THE EYE OR PRESS ⌥SPACE TO SPEAK" font:[HALTheme monoFontOfSize:8 weight:NSFontWeightMedium] color:[HALTheme secondaryText]];
    eyeHint.translatesAutoresizingMaskIntoConstraints = NO;
    [self.eyePanel addSubview:eyeHint];

    self.chatViewController = [[HALChatViewController alloc] initWithNibName:nil bundle:nil];
    self.chatViewController.onSendText = ^(NSString *text) {
        if (weakSelf.onSendText) weakSelf.onSendText(text);
    };
    self.chatViewController.onStop = ^{
        if (weakSelf.onStop) weakSelf.onStop();
    };
    [self addChildViewController:self.chatViewController];
    self.chatViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mainColumn addSubview:self.chatViewController.view];

    self.sidebarWidthConstraint = [self.sidebarViewController.view.widthAnchor constraintEqualToConstant:260];
    self.mainColumnTrailingConstraint = [self.mainColumn.trailingAnchor constraintEqualToAnchor:self.sidebarViewController.view.leadingAnchor];
    self.hiddenSidebarTrailingConstraint = [self.mainColumn.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor];
    self.eyeHeightConstraint = [self.eyePanel.heightAnchor constraintEqualToConstant:330];

    self.normalConstraints = @[
        [self.topBar.topAnchor constraintEqualToAnchor:root.topAnchor],
        [self.topBar.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
        [self.topBar.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
        [self.topBar.heightAnchor constraintEqualToConstant:48],

        [title.leadingAnchor constraintEqualToAnchor:self.topBar.leadingAnchor constant:84],
        [title.centerYAnchor constraintEqualToAnchor:self.topBar.centerYAnchor],
        [redDot.leadingAnchor constraintEqualToAnchor:title.trailingAnchor constant:10],
        [redDot.centerYAnchor constraintEqualToAnchor:title.centerYAnchor],
        [redDot.widthAnchor constraintEqualToConstant:8],
        [redDot.heightAnchor constraintEqualToConstant:8],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:redDot.trailingAnchor constant:10],
        [self.statusLabel.centerYAnchor constraintEqualToAnchor:self.topBar.centerYAnchor],

        [self.micButton.trailingAnchor constraintEqualToAnchor:self.topBar.trailingAnchor constant:-16],
        [self.micButton.centerYAnchor constraintEqualToAnchor:self.topBar.centerYAnchor],
        [settings.trailingAnchor constraintEqualToAnchor:self.micButton.leadingAnchor constant:-8],
        [settings.centerYAnchor constraintEqualToAnchor:self.topBar.centerYAnchor],
        [cinema.trailingAnchor constraintEqualToAnchor:settings.leadingAnchor constant:-8],
        [cinema.centerYAnchor constraintEqualToAnchor:self.topBar.centerYAnchor],
        [threeD.trailingAnchor constraintEqualToAnchor:cinema.leadingAnchor constant:-8],
        [threeD.centerYAnchor constraintEqualToAnchor:self.topBar.centerYAnchor],
        [sidebar.trailingAnchor constraintEqualToAnchor:threeD.leadingAnchor constant:-8],
        [sidebar.centerYAnchor constraintEqualToAnchor:self.topBar.centerYAnchor],
        [help.trailingAnchor constraintEqualToAnchor:sidebar.leadingAnchor constant:-8],
        [help.centerYAnchor constraintEqualToAnchor:self.topBar.centerYAnchor],

        [self.contentView.topAnchor constraintEqualToAnchor:self.topBar.bottomAnchor],
        [self.contentView.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
        [self.contentView.bottomAnchor constraintEqualToAnchor:root.bottomAnchor],

        [self.mainColumn.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.mainColumn.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.mainColumn.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],

        [self.sidebarViewController.view.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.sidebarViewController.view.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.sidebarViewController.view.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
        self.sidebarWidthConstraint,

        [self.eyePanel.topAnchor constraintEqualToAnchor:self.mainColumn.topAnchor constant:14],
        [self.eyePanel.leadingAnchor constraintEqualToAnchor:self.mainColumn.leadingAnchor constant:14],
        [self.eyePanel.trailingAnchor constraintEqualToAnchor:self.mainColumn.trailingAnchor constant:-14],
        self.eyeHeightConstraint,

        [self.eyeView.topAnchor constraintEqualToAnchor:self.eyePanel.topAnchor constant:8],
        [self.eyeView.leadingAnchor constraintEqualToAnchor:self.eyePanel.leadingAnchor constant:8],
        [self.eyeView.trailingAnchor constraintEqualToAnchor:self.eyePanel.trailingAnchor constant:-8],
        [self.eyeView.bottomAnchor constraintEqualToAnchor:self.eyePanel.bottomAnchor constant:-20],

        [eyeHint.centerXAnchor constraintEqualToAnchor:self.eyePanel.centerXAnchor],
        [eyeHint.bottomAnchor constraintEqualToAnchor:self.eyePanel.bottomAnchor constant:-7],

        [self.chatViewController.view.topAnchor constraintEqualToAnchor:self.eyePanel.bottomAnchor constant:10],
        [self.chatViewController.view.leadingAnchor constraintEqualToAnchor:self.mainColumn.leadingAnchor constant:14],
        [self.chatViewController.view.trailingAnchor constraintEqualToAnchor:self.mainColumn.trailingAnchor constant:-14],
        [self.chatViewController.view.bottomAnchor constraintEqualToAnchor:self.mainColumn.bottomAnchor constant:-12]
    ];
    [NSLayoutConstraint activateConstraints:self.normalConstraints];
    self.mainColumnTrailingConstraint.active = YES;

    self.compactConstraints = @[
        [self.eyePanel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.eyePanel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.eyePanel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.eyePanel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
        [self.eyeView.topAnchor constraintEqualToAnchor:self.eyePanel.topAnchor constant:8],
        [self.eyeView.leadingAnchor constraintEqualToAnchor:self.eyePanel.leadingAnchor constant:8],
        [self.eyeView.trailingAnchor constraintEqualToAnchor:self.eyePanel.trailingAnchor constant:-8],
        [self.eyeView.bottomAnchor constraintEqualToAnchor:self.eyePanel.bottomAnchor constant:-8]
    ];

    [self applyConfiguration];
    [self refreshSimulator];
}

- (NSTextField *)labelWithString:(NSString *)string font:(NSFont *)font color:(NSColor *)color {
    NSTextField *label = [NSTextField labelWithString:string];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = font;
    label.textColor = color;
    label.selectable = YES;
    return label;
}

- (NSButton *)topBarButton:(NSString *)title action:(SEL)action {
    NSButton *button = [[NSButton alloc] initWithFrame:NSZeroRect];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.bordered = NO;
    button.target = self;
    button.action = action;
    button.wantsLayer = YES;
    button.layer.cornerRadius = 4.0;
    button.layer.backgroundColor = [[HALTheme text] colorWithAlphaComponent:0.03].CGColor;
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment = NSTextAlignmentCenter;
    button.attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:@{
        NSFontAttributeName: [HALTheme monoFontOfSize:9 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName: [HALTheme secondaryText],
        NSParagraphStyleAttributeName: paragraph
    }];
    [button.widthAnchor constraintGreaterThanOrEqualToConstant:52].active = YES;
    [button.heightAnchor constraintEqualToConstant:24].active = YES;
    return button;
}

- (void)applyConfiguration {
    self.eyeView.eyeColor = [HALTheme colorFromHex:self.configuration.eyeColorHex];
    self.eyeView.glowIntensity = self.configuration.glowIntensity;
    self.eyeView.pulseSpeed = self.configuration.pulseSpeed;
    self.eyeView.eyeScale = self.configuration.eyeScale;
    self.eyeView.scanlinesEnabled = self.configuration.scanlines;
    self.eyeView.grainEnabled = self.configuration.grain;
    self.eyeView.trackCursorEnabled = self.configuration.trackCursor;
    self.eyeView.blinkEnabled = self.configuration.blinkEnabled;
    self.eyeView.blinkInterval = self.configuration.blinkInterval;
    BOOL systemReduce = [NSWorkspace sharedWorkspace].accessibilityDisplayShouldReduceMotion;
    if ([self.configuration.reduceMotionMode isEqualToString:@"on"]) {
        self.eyeView.reduceMotion = YES;
    } else if ([self.configuration.reduceMotionMode isEqualToString:@"off"]) {
        self.eyeView.reduceMotion = NO;
    } else {
        self.eyeView.reduceMotion = systemReduce;
    }
    [self.eyeView setNeedsDisplay:YES];
    [self setSidebarVisible:self.configuration.showTelemetry];
}

- (void)refreshAppearance {
    [self applyConfiguration];
}

- (void)refreshSimulator {
    [self.sidebarViewController refresh];
    [self setStatusText:[NSString stringWithFormat:@"%@ · %@", self.simulator.scenario.name.uppercaseString, [self.simulator missionTimeString]]];
}

- (void)setEyeState:(HALEyeState)state {
    [self.eyeView setState:state animated:YES];
}

- (void)setStatusText:(NSString *)text {
    self.statusLabel.stringValue = text.uppercaseString;
}

- (void)setListening:(BOOL)listening preview:(NSString *)preview {
    self.listening = listening;
    [self.micButton setAttributedTitle:[[NSAttributedString alloc] initWithString:listening ? @"■ STOP" : @"● LISTEN" attributes:@{
        NSFontAttributeName: [HALTheme monoFontOfSize:9 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName: listening ? [HALTheme listening] : [HALTheme secondaryText]
    }]];
    if (listening) {
        [self setStatusText:preview.length > 0 ? [NSString stringWithFormat:@"LISTENING · %@", preview] : @"LISTENING"];
    } else {
        [self refreshSimulator];
    }
}

- (void)appendMessage:(HALMessage *)message {
    [self.chatViewController appendMessage:message];
}

- (void)appendMessages:(NSArray<HALMessage *> *)messages {
    [self.chatViewController appendMessages:messages];
}

- (void)beginStreamingReply {
    [self.chatViewController beginStreamingHALReply];
}

- (void)updateStreamingReply:(NSString *)text {
    [self.chatViewController updateStreamingText:text];
}

- (void)finishStreamingReply:(HALMessage *)message {
    [self.chatViewController finishStreamingWithMessage:message];
}

- (void)cancelStreamingReply {
    [self.chatViewController cancelStreaming];
}

- (void)clearTranscript {
    [self.chatViewController clearTranscript];
}

- (void)toggleSidebar {
    [self setSidebarVisible:!self.sidebarVisible];
}

- (void)setSidebarVisible:(BOOL)visible {
    if (self.compactMode) return;
    _sidebarVisible = visible;
    self.sidebarWidthConstraint.constant = 260;
    // Deactivate the outgoing trailing constraint before activating the new
    // one. Having both active at once creates an unsatisfiable transient
    // layout and can throw from NSLayoutConstraint on newer macOS versions.
    if (visible) {
        self.hiddenSidebarTrailingConstraint.active = NO;
        self.mainColumnTrailingConstraint.active = YES;
    } else {
        self.mainColumnTrailingConstraint.active = NO;
        self.hiddenSidebarTrailingConstraint.active = YES;
    }
    self.sidebarViewController.view.hidden = !visible;
}

- (void)setCompactMode:(BOOL)compact {
    if (self.compactMode == compact) return;
    _compactMode = compact;
    if (compact) {
        [NSLayoutConstraint deactivateConstraints:self.normalConstraints];
        self.mainColumnTrailingConstraint.active = NO;
        self.hiddenSidebarTrailingConstraint.active = NO;
        self.topBar.hidden = YES;
        self.sidebarViewController.view.hidden = YES;
        self.chatViewController.view.hidden = YES;
        [NSLayoutConstraint activateConstraints:self.compactConstraints];
    } else {
        [NSLayoutConstraint deactivateConstraints:self.compactConstraints];
        self.topBar.hidden = NO;
        self.chatViewController.view.hidden = NO;
        [NSLayoutConstraint activateConstraints:self.normalConstraints];
        [self setSidebarVisible:self.sidebarVisible];
    }
    [self.view layoutSubtreeIfNeeded];
}

- (void)focusInput {
    [self.chatViewController focusInput];
}

- (void)micPressed:(id)sender {
    if (self.onToggleListening) self.onToggleListening();
}

- (void)settingsPressed:(id)sender {
    if (self.onOpenSettings) self.onOpenSettings();
}

- (void)cinemaPressed:(id)sender {
    if (self.onOpenCinema) self.onOpenCinema();
}

- (void)threeDPressed:(id)sender {
    if (self.onOpen3D) self.onOpen3D();
}

- (void)helpPressed:(id)sender {
    if (self.onOpenHelp) self.onOpenHelp();
}

- (void)sidebarPressed:(id)sender {
    [self toggleSidebar];
}

@end
