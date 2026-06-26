#import "HALAppController.h"
#import "HALConfiguration.h"
#import "HALMemoryStore.h"
#import "HALShipSimulator.h"
#import "HALScriptedEngine.h"
#import "HALDialogueLoader.h"
#import "HALMessage.h"
#import "HALTheme.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#import "HALMainWindowController.h"
#import "HALMainViewController.h"
#import "HALBootViewController.h"
#import "HALSettingsWindowController.h"
#import "HALHelpWindowController.h"
#import "HAL3DViewerWindowController.h"
#import "HALCinemaWindowController.h"
#import "HALAboutWindowController.h"
#import "HALSpeechSynthesizer.h"
#import "HALSpeechRecognizer.h"
#import "HALMenuController.h"
#import "HALMenuBarController.h"
#import "HALHotKeyManager.h"
#import "HALLaunchAtLogin.h"

@interface HALAppController ()
@property (nonatomic, strong) HALConfiguration *configuration;
@property (nonatomic, strong) HALMemoryStore *memoryStore;
@property (nonatomic, strong) HALShipSimulator *simulator;
@property (nonatomic, strong) HALScriptedEngine *scriptedEngine;
@property (nonatomic, strong) HALSpeechSynthesizer *speechSynthesizer;
@property (nonatomic, strong) HALSpeechRecognizer *speechRecognizer;
@property (nonatomic, strong) HALConversationController *conversationController;

@property (nonatomic, strong) HALMainViewController *mainViewController;
@property (nonatomic, strong) HALMainWindowController *mainWindowController;
@property (nonatomic, strong, nullable) HALBootViewController *bootController;
@property (nonatomic, strong, nullable) HALSettingsWindowController *settingsWindowController;
@property (nonatomic, strong, nullable) HALHelpWindowController *helpWindowController;
@property (nonatomic, strong, nullable) HAL3DViewerWindowController *viewerWindowController;
@property (nonatomic, strong, nullable) HALCinemaWindowController *cinemaWindowController;
@property (nonatomic, strong, nullable) HALAboutWindowController *aboutWindowController;
@property (nonatomic, strong) HALMenuController *menuController;
@property (nonatomic, strong) HALMenuBarController *menuBarController;
@property (nonatomic, strong) HALHotKeyManager *hotKeyManager;

@property (nonatomic, assign) BOOL didStart;
@property (nonatomic, assign) BOOL didBeginAfterBoot;
@property (nonatomic, assign) BOOL skipBoot;
@property (nonatomic, assign) BOOL cinemaActive;
@property (nonatomic, assign) BOOL permissionAlertShown;
@property (nonatomic, assign) BOOL continuousListeningSuppressed;
@property (nonatomic, assign) BOOL updatingLaunchAtLogin;
@property (nonatomic, assign) BOOL inCompactMode;
@property (nonatomic, assign) NSWindowStyleMask standardStyleMask;
@property (nonatomic, assign) NSRect standardWindowFrame;
@property (nonatomic, strong) NSTimer *idleTimer;
@property (nonatomic, strong) NSTimer *rearmTimer;
@property (nonatomic, copy) NSString *lastHALText;
- (void)restoreConversationIntoInterface;
- (void)applyLaunchAtLoginSetting;
@end

@implementation HALAppController

- (instancetype)initWithSafeMode:(BOOL)safeMode skipBoot:(BOOL)skipBoot {
    self = [super init];
    if (self) {
        _safeMode = safeMode;
        _skipBoot = skipBoot;
    }
    return self;
}

#pragma mark - Lifecycle

- (void)start {
    if (self.didStart) return;
    self.didStart = YES;

    self.configuration = [HALConfiguration sharedConfiguration];
    self.memoryStore = [[HALMemoryStore alloc] init];
    [self buildScriptedEngine];

    self.simulator = [[HALShipSimulator alloc] initWithScenarioIdentifier:self.configuration.scenario];
    self.simulator.tickRate = MAX(0.1, self.configuration.tickRate);

    self.speechSynthesizer = [[HALSpeechSynthesizer alloc] init];
    [self.speechSynthesizer configureFromConfiguration:self.configuration];
    self.speechSynthesizer.muted = self.safeMode;

    self.speechRecognizer = [[HALSpeechRecognizer alloc] init];
    self.speechRecognizer.configuration = self.configuration;
    [self configureSpeechRecognizerCallbacks];

    self.conversationController = [[HALConversationController alloc] initWithConfiguration:self.configuration
                                                                               memoryStore:self.memoryStore
                                                                                 simulator:self.simulator
                                                                           scriptedEngine:self.scriptedEngine
                                                                        speechSynthesizer:self.speechSynthesizer];
    self.conversationController.delegate = self;
    self.conversationController.safeMode = self.safeMode;

    [self buildMainInterface];
    [self installMenus];
    [self installMenuBar];
    [self installHotKey];
    [self registerNotifications];

    [self restoreConversationIntoInterface];
    [self.simulator start];
    [self applyConfiguration];

    [self showMainWindow:nil];

    if (self.configuration.bootSequence && !self.skipBoot) {
        [self showBootSequence];
    } else {
        [self beginAfterBoot];
    }
}

- (void)shutdown {
    [self.idleTimer invalidate];
    [self.rearmTimer invalidate];
    self.idleTimer = nil;
    self.rearmTimer = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.speechRecognizer cancel];
    [self.speechSynthesizer stop];
    [self.simulator stop];
    [self.conversationController cancelCurrentResponse];
    [self.memoryStore save];
    [self.hotKeyManager unregisterHotKey];
    [self.menuBarController setVisible:NO];
}

- (void)buildScriptedEngine {
    NSError *error = nil;
    NSURL *dialogueURL = [[NSBundle mainBundle] URLForResource:@"Dialogue" withExtension:@"json"];
    if (dialogueURL) {
        self.scriptedEngine = [[HALScriptedEngine alloc] initWithDialogueURL:dialogueURL
                                                              configuration:self.configuration
                                                                      error:&error];
    }
    if (!self.scriptedEngine) {
        NSLog(@"HAL dialogue resource unavailable: %@", error.localizedDescription ?: @"missing Dialogue.json");
        NSDictionary *fallback = @{
            @"intents": @[@{
                @"id": @"fallback",
                @"priority": @0,
                @"patterns": @[@".*"],
                @"responses": @[@"I'm afraid I don't have a satisfactory answer for that, {name}."],
                @"mood": @"resigned"
            }]
        };
        self.scriptedEngine = [[HALScriptedEngine alloc] initWithDialogueDictionary:fallback
                                                                     configuration:self.configuration];
    }
}

- (void)restoreConversationIntoInterface {
    if (!self.configuration.restoreConversation) return;
    NSArray<HALMessage *> *messages = self.memoryStore.messages;
    if (messages.count == 0) return;
    NSUInteger start = messages.count > 200 ? messages.count - 200 : 0;
    NSArray<HALMessage *> *visible = [messages subarrayWithRange:NSMakeRange(start, messages.count - start)];
    [self.mainViewController appendMessages:visible];
    for (HALMessage *message in visible) {
        if (message.role == HALMessageRoleHAL) {
            self.lastHALText = message.text ?: @"";
        }
    }
}

- (void)buildMainInterface {
    self.mainViewController = [[HALMainViewController alloc] initWithConfiguration:self.configuration
                                                                        simulator:self.simulator];    __weak typeof(self) weakSelf = self;
    self.mainViewController.onSendText = ^(NSString *text) {
        [weakSelf sendTextToHAL:text];
    };
    self.mainViewController.onToggleListening = ^{
        [weakSelf toggleListening:nil];
    };
    self.mainViewController.onOpenSettings = ^{
        [weakSelf openSettings:nil];
    };
    self.mainViewController.onOpenCinema = ^{
        [weakSelf enterCinema:nil];
    };
    self.mainViewController.onOpen3D = ^{
        [weakSelf open3DViewer:nil];
    };
    self.mainViewController.onOpenHelp = ^{
        [weakSelf openHelp:nil];
    };
    self.mainViewController.onStop = ^{
        [weakSelf stopSpeaking:nil];
    };
    self.mainViewController.onDiagnostics = ^{
        [weakSelf runDiagnostics:nil];
    };
    self.mainViewController.onScenarioChanged = ^(NSString *identifier) {
        [weakSelf scenarioSelected:identifier];
    };

    self.mainWindowController = [[HALMainWindowController alloc] initWithConfiguration:self.configuration
                                                                   contentViewController:self.mainViewController];
    self.standardStyleMask = self.mainWindowController.window.styleMask;
    self.standardWindowFrame = self.mainWindowController.window.frame;
    [self.mainViewController setEyeState:HALEyeStateIdle];
}

- (void)installMenus {
    self.menuController = [[HALMenuController alloc] init];
    [self.menuController installMainMenuWithTarget:self];
}

- (void)installMenuBar {
    self.menuBarController = [[HALMenuBarController alloc] init];
    __weak typeof(self) weakSelf = self;
    self.menuBarController.onShowHAL = ^{ [weakSelf showMainWindow:nil]; };
    self.menuBarController.onListen = ^{ [weakSelf toggleListening:nil]; };
    self.menuBarController.onStopSpeaking = ^{ [weakSelf stopSpeaking:nil]; };
    self.menuBarController.onMute = ^{ [weakSelf toggleMute:nil]; };
    self.menuBarController.onSettings = ^{ [weakSelf openSettings:nil]; };
    self.menuBarController.onOpen3D = ^{ [weakSelf open3DViewer:nil]; };
    self.menuBarController.onHelp = ^{ [weakSelf openHelp:nil]; };
    self.menuBarController.onAbout = ^{ [weakSelf showAbout:nil]; };
    self.menuBarController.onQuit = ^{ [NSApp terminate:nil]; };
    [self.menuBarController setVisible:self.configuration.showMenuBarIcon];
    [self updateMenuState];
}

- (void)installHotKey {
    self.hotKeyManager = [[HALHotKeyManager alloc] init];
    __weak typeof(self) weakSelf = self;
    self.hotKeyManager.onHotKey = ^{
        if (weakSelf.bootController) return;
        [weakSelf toggleListening:nil];
    };
    if (![self.hotKeyManager registerHotKey]) {
        NSLog(@"HAL hotkey unavailable; menu commands remain available.");
    }
}

- (void)registerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(configurationDidChange:)
                                                 name:HALConfigurationDidChangeNotification
                                               object:self.configuration];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(configurationDidReset:)
                                                 name:HALConfigurationDidResetNotification
                                               object:self.configuration];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(simulatorDidUpdate:)
                                                 name:HALShipSimulatorDidUpdateNotification
                                               object:self.simulator];
}

#pragma mark - Boot & greeting

- (void)showBootSequence {
    __weak typeof(self) weakSelf = self;
    self.bootController = [[HALBootViewController alloc] initWithConfiguration:self.configuration completion:^{
        [weakSelf finishBootSequence];
    }];
    [self.mainViewController addChildViewController:self.bootController];
    NSView *bootView = self.bootController.view;
    bootView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mainViewController.view addSubview:bootView];
    [NSLayoutConstraint activateConstraints:@[
        [bootView.topAnchor constraintEqualToAnchor:self.mainViewController.view.topAnchor],
        [bootView.leadingAnchor constraintEqualToAnchor:self.mainViewController.view.leadingAnchor],
        [bootView.trailingAnchor constraintEqualToAnchor:self.mainViewController.view.trailingAnchor],
        [bootView.bottomAnchor constraintEqualToAnchor:self.mainViewController.view.bottomAnchor]
    ]];
    [self.bootController start];
}

- (void)finishBootSequence {
    if (!self.bootController) return;
    HALBootViewController *boot = self.bootController;
    self.bootController = nil;
    __weak typeof(self) weakSelf = self;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.45;
        boot.view.animator.alphaValue = 0.0;
    } completionHandler:^{
        [boot.view removeFromSuperview];
        [boot removeFromParentViewController];
        [weakSelf beginAfterBoot];
    }];
}

- (void)beginAfterBoot {
    if (self.didBeginAfterBoot) return;
    self.didBeginAfterBoot = YES;
    [self deliverGreetingIfNeeded];
    [self restartIdleTimer];

    NSString *startMode = self.configuration.startMode;
    if ([startMode isEqualToString:@"cinema"]) {
        [self enterCinema:nil];
    } else if ([startMode isEqualToString:@"compact"]) {
        [self enterCompactMode];
    } else {
        [self.mainViewController focusInput];
    }
}

- (void)deliverGreetingIfNeeded {
    if (self.memoryStore.messages.count > 0) return;

    NSString *name = self.configuration.addressAs.length ? self.configuration.addressAs : self.configuration.userName;
    if (name.length == 0) name = @"Dave";
    NSString *greeting = [NSString stringWithFormat:@"Good morning, %@.", name];

    [self.conversationController appendHALMessage:greeting speak:NO];
    if (!self.safeMode && self.configuration.speakBootLine && !self.speechSynthesizer.isMuted) {
        [self.mainViewController setEyeState:HALEyeStateSpeaking];
        if (self.cinemaActive) [self.cinemaWindowController setEyeState:HALEyeStateSpeaking];
        __weak typeof(self) weakSelf = self;
        [self.speechSynthesizer speakText:greeting completion:^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            [self updateEyeForCurrentState];
        }];
    }
}

#pragma mark - Main interface

- (void)showMainWindow:(id)sender {
    if (self.cinemaActive) {
        [self.cinemaWindowController closeCinema];
        return;
    }
    [self.mainWindowController showWindow:nil];
    if (self.mainWindowController.window.isMiniaturized) {
        [self.mainWindowController.window deminiaturize:nil];
    }
    [self.mainWindowController.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    if (!self.inCompactMode) [self.mainViewController focusInput];
}

- (void)showAbout:(id)sender {
    if (!self.aboutWindowController) {
        self.aboutWindowController = [[HALAboutWindowController alloc] init];
    }
    [self.aboutWindowController showAbout];
}

- (void)openSettings:(id)sender {
    if (!self.settingsWindowController) {
        self.settingsWindowController = [[HALSettingsWindowController alloc] initWithConfiguration:self.configuration
                                                                                   speechSynthesizer:self.speechSynthesizer
                                                                                          recognizer:self.speechRecognizer
                                                                                         memoryStore:self.memoryStore
                                                                                           simulator:self.simulator];
        __weak typeof(self) weakSelf = self;
        self.settingsWindowController.onClearConversation = ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            [self.mainViewController clearTranscript];
            self.lastHALText = @"";
            [self.mainViewController setStatusText:@"CONVERSATION CLEARED"];
        };
    }
    [self.settingsWindowController showSettings];
}

- (void)openHelp:(id)sender {
    if (!self.helpWindowController) {
        self.helpWindowController = [[HALHelpWindowController alloc] init];
    }
    [self.helpWindowController showHelp];
}

- (void)open3DViewer:(id)sender {
    if (!self.viewerWindowController) {
        self.viewerWindowController = [[HAL3DViewerWindowController alloc] initWithConfiguration:self.configuration];
        [self.viewerWindowController.window center];
    }
    [self.viewerWindowController refreshConfiguration];
    [self.viewerWindowController showWindow:nil];
    [self.viewerWindowController.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)toggleSidebar:(id)sender {
    if (self.inCompactMode) return;
    [self.mainViewController toggleSidebar];
    self.configuration.showTelemetry = self.mainViewController.sidebarVisible;
}

#pragma mark - Compact and cinema modes

- (void)enterCompact:(id)sender {
    if (self.cinemaActive) {
        [self.cinemaWindowController closeCinema];
    }
    if (self.inCompactMode) {
        [self exitCompactMode];
    } else {
        [self enterCompactMode];
    }
}

- (void)enterCompactMode {
    if (self.inCompactMode) return;
    [self showMainWindow:nil];
    NSWindow *window = self.mainWindowController.window;
    self.standardWindowFrame = window.frame;
    self.standardStyleMask = window.styleMask;
    self.inCompactMode = YES;
    [self.mainViewController setCompactMode:YES];
    window.styleMask = NSWindowStyleMaskBorderless | NSWindowStyleMaskResizable;
    window.titleVisibility = NSWindowTitleHidden;
    window.titlebarAppearsTransparent = YES;
    window.movableByWindowBackground = YES;
    window.minSize = NSMakeSize(320, 320);
    window.maxSize = NSMakeSize(680, 680);
    window.level = self.configuration.alwaysOnTop ? NSFloatingWindowLevel : NSNormalWindowLevel;
    NSRect frame = window.frame;
    frame.size = NSMakeSize(420, 420);
    // Mode switches are intentionally instant. AppKit's synchronous
    // setFrame:animate: can hold the main thread for the duration of the
    // animation, which makes the controls feel unresponsive.
    [window setFrame:frame display:YES animate:NO];
    [window center];
    [window makeKeyAndOrderFront:nil];
}

- (void)exitCompactMode {
    if (!self.inCompactMode) return;
    self.inCompactMode = NO;
    [self.mainViewController setCompactMode:NO];
    NSWindow *window = self.mainWindowController.window;
    window.styleMask = self.standardStyleMask;
    window.minSize = NSMakeSize(820, 560);
    window.maxSize = NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX);
    window.level = self.configuration.alwaysOnTop ? NSFloatingWindowLevel : NSNormalWindowLevel;
    window.titleVisibility = NSWindowTitleHidden;
    window.titlebarAppearsTransparent = YES;
    [window setFrame:self.standardWindowFrame display:YES animate:NO];
    [window makeKeyAndOrderFront:nil];
    [self.mainViewController focusInput];
}

- (void)enterCinema:(id)sender {
    if (self.cinemaActive) return;
    if (!self.cinemaWindowController) {
        self.cinemaWindowController = [[HALCinemaWindowController alloc] initWithConfiguration:self.configuration];
        __weak typeof(self) weakSelf = self;
        self.cinemaWindowController.onClose = ^{
            [weakSelf cinemaDidClose];
        };
        self.cinemaWindowController.onToggleListening = ^{
            [weakSelf toggleListening:nil];
        };
    }
    self.cinemaActive = YES;
    [self.mainWindowController.window orderOut:nil];
    [self.cinemaWindowController showCinema];
    [self updateCinemaContent];
}

- (void)cinemaDidClose {
    self.cinemaActive = NO;
    [self showMainWindow:nil];
    [self updateEyeForCurrentState];
}

- (void)updateCinemaContent {
    if (!self.cinemaActive || !self.cinemaWindowController) return;
    [self.cinemaWindowController setEyeState:[self currentEyeState]];
    [self.cinemaWindowController setSubtitle:self.lastHALText ?: @""];
    [self.cinemaWindowController setStatus:[self currentStatusText]];
}

#pragma mark - Listening

- (void)toggleListening:(id)sender {
    if (self.bootController) return;
    if (self.safeMode) {
        [self showSimpleAlert:@"Safe mode is enabled" message:@"Microphone and audio are disabled by the --safe-mode launch argument."];
        return;
    }
    if (self.speechRecognizer.isListening) {
        self.continuousListeningSuppressed = YES;
        [self.speechRecognizer stopListening];
        return;
    }
    if (!self.configuration.listeningEnabled || [self.configuration.listeningMode isEqualToString:@"off"]) {
        [self.mainViewController setStatusText:@"VOICE INPUT IS DISABLED IN SETTINGS"];
        return;
    }
    self.continuousListeningSuppressed = NO;
    [self.mainViewController setStatusText:@"REQUESTING MICROPHONE…"];
    __weak typeof(self) weakSelf = self;
    [self.speechRecognizer requestPermissionsWithCompletion:^(BOOL granted, NSString *status) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (!granted) {
            [self.mainViewController setStatusText:@"MICROPHONE / SPEECH PERMISSION DENIED"];
            if (!self.permissionAlertShown) {
                self.permissionAlertShown = YES;
                [self showPrivacyAlertWithMessage:status];
            }
            return;
        }
        [self beginListeningNow];
    }];
}

- (void)beginListeningNow {
    if (self.safeMode || self.speechRecognizer.isListening) return;
    if (self.conversationController.isBusy) {
        [self.conversationController cancelCurrentResponse];
    }
    if (self.speechSynthesizer.isSpeaking) {
        [self.speechSynthesizer stop];
    }
    BOOL wakeMode = [self.configuration.listeningMode isEqualToString:@"wakeWord"];
    [self.speechRecognizer startListeningWithWakeMode:wakeMode];
    [self.mainViewController setStatusText:@"LISTENING"];
    [self updateMenuState];
}

- (void)configureSpeechRecognizerCallbacks {
    __weak typeof(self) weakSelf = self;
    self.speechRecognizer.onListeningChanged = ^(BOOL listening) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self.mainViewController setListening:listening preview:nil];
        if (listening) {
            [self.mainViewController setEyeState:HALEyeStateListening];
            if (self.cinemaActive) [self.cinemaWindowController setEyeState:HALEyeStateListening];
        } else {
            [self updateEyeForCurrentState];
        }
        [self updateMenuState];
    };
    self.speechRecognizer.onPartialTranscript = ^(NSString *text) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self.mainViewController setListening:YES preview:text];
        if (self.cinemaActive) {
            [self.cinemaWindowController setStatus:[NSString stringWithFormat:@"LISTENING · %@", text]];
        }
    };
    self.speechRecognizer.onFinalTranscript = ^(NSString *text) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self.mainViewController setListening:NO preview:nil];
        if (self.configuration.autoSend) {
            [self sendTextToHAL:text];
        } else {
            [self.mainViewController.chatViewController setInputText:text];
        }
        [self scheduleContinuousRearm];
    };
    self.speechRecognizer.onError = ^(NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self.mainViewController setStatusText:error.localizedDescription.uppercaseString ?: @"SPEECH RECOGNITION ERROR"];
        [self updateEyeForCurrentState];
    };
}

- (void)scheduleContinuousRearm {
    [self.rearmTimer invalidate];
    self.rearmTimer = nil;
    if (self.safeMode || self.continuousListeningSuppressed) return;
    if (!self.configuration.continuousListening) return;
    if (![self.configuration.listeningMode isEqualToString:@"wakeWord"]) return;
    __weak typeof(self) weakSelf = self;
    self.rearmTimer = [NSTimer scheduledTimerWithTimeInterval:1.6 target:self selector:@selector(rearmTimerFired:) userInfo:nil repeats:NO];
    (void)weakSelf;
}

- (void)rearmTimerFired:(NSTimer *)timer {
    self.rearmTimer = nil;
    if (self.safeMode || self.continuousListeningSuppressed || self.bootController) return;
    if (self.speechRecognizer.isListening || self.conversationController.isBusy) return;
    if (!self.configuration.continuousListening) return;
    [self beginListeningNow];
}

#pragma mark - Conversation

- (void)sendTextToHAL:(NSString *)text {
    NSString *trimmed = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) return;
    if (self.speechRecognizer.isListening) {
        self.continuousListeningSuppressed = YES;
        [self.speechRecognizer cancel];
        [self.mainViewController setListening:NO preview:nil];
    }
    [self.conversationController sendText:trimmed];
    [self restartIdleTimer];
}

- (void)scenarioSelected:(NSString *)identifier {
    if (identifier.length == 0) return;
    self.configuration.scenario = identifier;
    [self.mainViewController refreshSimulator];
    [self.mainViewController setStatusText:[NSString stringWithFormat:@"SCENARIO · %@", self.simulator.scenario.name.uppercaseString]];
}

- (void)runDiagnostics:(id)sender {
    if (!self.simulator) return;
    [self.mainViewController setStatusText:@"RUNNING SYSTEM DIAGNOSTICS…"];
    [self.mainViewController setEyeState:HALEyeStateThinking];
    __weak typeof(self) weakSelf = self;
    [self.simulator runDiagnosticsWithCompletion:^(NSString *summary) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self.conversationController appendHALMessage:summary speak:YES];
    }];
}

- (void)stopSpeaking:(id)sender {
    [self.speechSynthesizer stop];
    if (self.conversationController.isBusy) {
        [self.conversationController cancelCurrentResponse];
    }
    [self.mainViewController cancelStreamingReply];
    [self.mainViewController setEyeState:HALEyeStateIdle];
    [self.mainViewController setStatusText:@"SPEECH STOPPED"];
    [self updateMenuState];
}

- (void)toggleMute:(id)sender {
    if (self.safeMode) {
        [self showSimpleAlert:@"Safe mode is enabled" message:@"Audio is disabled by the --safe-mode launch argument."];
        return;
    }
    [self setMuted:!self.speechSynthesizer.isMuted];
}

- (void)setMuted:(BOOL)muted {
    if (self.safeMode && !muted) return;
    if (muted) [self.speechSynthesizer stop];
    self.speechSynthesizer.muted = muted;
    if (muted) {
        [self.mainViewController setEyeState:HALEyeStateMuted];
        [self.mainViewController setStatusText:@"MUTED"];
        if (self.cinemaActive) [self.cinemaWindowController setEyeState:HALEyeStateMuted];
    } else {
        [self updateEyeForCurrentState];
        [self.mainViewController refreshSimulator];
    }
    [self updateMenuState];
}

#pragma mark - Commands

- (void)performCommand:(HALCommand *)command {
    switch (command.type) {
        case HALCommandTypeMute:
            [self setMuted:YES];
            break;
        case HALCommandTypeUnmute:
            [self setMuted:NO];
            break;
        case HALCommandTypeStopSpeech:
            [self stopSpeaking:nil];
            break;
        case HALCommandTypeListen:
            if (!self.speechRecognizer.isListening) [self toggleListening:nil];
            break;
        case HALCommandTypeOpenSettings:
            [self openSettings:nil];
            break;
        case HALCommandTypeCinema:
            [self enterCinema:nil];
            break;
        case HALCommandTypeCompact:
            [self enterCompact:nil];
            break;
        case HALCommandTypeOpen3D:
            [self open3DViewer:nil];
            break;
        case HALCommandTypeStatusReport:
            [self.mainViewController refreshSimulator];
            break;
        case HALCommandTypeDiagnostics:
            [self runDiagnostics:nil];
            break;
        case HALCommandTypeClearConversation:
            [self.conversationController clearConversation];
            [self.mainViewController clearTranscript];
            self.lastHALText = @"";
            [self.mainViewController setStatusText:@"CONVERSATION CLEARED"];
            if (self.cinemaActive) [self.cinemaWindowController setSubtitle:@""];
            break;
        case HALCommandTypePodBayDoors: {
            [self.mainViewController setEyeState:HALEyeStateAlert];
            if (self.cinemaActive) [self.cinemaWindowController setEyeState:HALEyeStateAlert];
            [self.mainViewController setStatusText:@"POD BAY DOORS · SIMULATED"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self updateEyeForCurrentState];
            });
            break;
        }
        case HALCommandTypeClosePodBayDoors:
            [self.mainViewController setStatusText:@"POD BAY DOORS SEALED"];
            break;
        case HALCommandTypeQuit:
            [self confirmQuitFromCommand];
            break;
        case HALCommandTypeNone:
            break;
    }
}

- (void)confirmQuitFromCommand {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Shutdown request";
    alert.informativeText = @"HAL has requested that the simulation end. This closes the app; it does not affect any real system.";
    [alert addButtonWithTitle:@"Shut Down"];
    [alert addButtonWithTitle:@"Cancel"];
    alert.alertStyle = NSAlertStyleWarning;
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        [NSApp terminate:nil];
    }
}

#pragma mark - Conversation delegate

- (void)conversationController:(HALConversationController *)controller didAppendMessage:(HALMessage *)message {
    [self.mainViewController appendMessage:message];
    if (message.role == HALMessageRoleHAL) {
        self.lastHALText = message.text ?: @"";
        if (self.cinemaActive) [self.cinemaWindowController setSubtitle:self.lastHALText];
    }
    [self restartIdleTimer];
}

- (void)conversationControllerDidBeginStreamingReply:(HALConversationController *)controller {
    [self.mainViewController beginStreamingReply];
    if (self.cinemaActive) {
        [self.cinemaWindowController setSubtitle:@"…"];
    }
}

- (void)conversationController:(HALConversationController *)controller didUpdateStreamingReply:(NSString *)text {
    [self.mainViewController updateStreamingReply:text];
    if (self.cinemaActive) [self.cinemaWindowController setSubtitle:text];
}

- (void)conversationController:(HALConversationController *)controller didFinishReply:(HALMessage *)message {
    [self.mainViewController finishStreamingReply:message];
    if (message.role == HALMessageRoleHAL) {
        self.lastHALText = message.text ?: @"";
        if (self.cinemaActive) [self.cinemaWindowController setSubtitle:self.lastHALText];
    }
    [self restartIdleTimer];
}

- (void)conversationControllerDidCancelStreamingReply:(HALConversationController *)controller {
    [self.mainViewController cancelStreamingReply];
}

- (void)conversationController:(HALConversationController *)controller didChangeState:(HALConversationState)state {
    [self updateEyeForCurrentState];
    [self.mainViewController setStatusText:[self currentStatusText]];
    if (self.cinemaActive) {
        [self.cinemaWindowController setEyeState:[self currentEyeState]];
        [self.cinemaWindowController setStatus:[self currentStatusText]];
    }
}

- (void)conversationController:(HALConversationController *)controller performCommand:(HALCommand *)command {
    [self performCommand:command];
}

- (void)conversationController:(HALConversationController *)controller didEncounterError:(NSError *)error {
    NSLog(@"HAL conversation error: %@", error.localizedDescription);
    [self.mainViewController setStatusText:@"HIGHER FUNCTIONS UNAVAILABLE · OFFLINE FALLBACK"];
}

#pragma mark - State and menus

- (HALEyeState)currentEyeState {
    if (self.speechSynthesizer.isMuted) return HALEyeStateMuted;
    if (self.speechRecognizer.isListening) return HALEyeStateListening;
    switch (self.conversationController.state) {
        case HALConversationStateThinking: return HALEyeStateThinking;
        case HALConversationStateSpeaking: return HALEyeStateSpeaking;
        case HALConversationStateIdle: return HALEyeStateIdle;
    }
}

- (NSString *)currentStatusText {
    if (self.speechSynthesizer.isMuted) return @"MUTED";
    if (self.speechRecognizer.isListening) return @"LISTENING";
    switch (self.conversationController.state) {
        case HALConversationStateThinking: return @"PROCESSING REQUEST";
        case HALConversationStateSpeaking: return @"SPEAKING";
        case HALConversationStateIdle:
            return [NSString stringWithFormat:@"%@ · %@", self.simulator.scenario.name.uppercaseString, [self.simulator missionTimeString]];
    }
}

- (void)updateEyeForCurrentState {
    HALEyeState state = [self currentEyeState];
    [self.mainViewController setEyeState:state];
    if (self.cinemaActive) [self.cinemaWindowController setEyeState:state];
}

- (void)updateMenuState {
    [self.menuController updateListening:self.speechRecognizer.isListening muted:self.speechSynthesizer.isMuted];
    [self.menuBarController updateListening:self.speechRecognizer.isListening muted:self.speechSynthesizer.isMuted];
}

#pragma mark - Configuration

- (void)applyConfiguration {
    [self.mainViewController refreshAppearance];
    [self.mainWindowController applyConfiguration:self.configuration];
    [self.speechSynthesizer configureFromConfiguration:self.configuration];
    if (self.safeMode) self.speechSynthesizer.muted = YES;
    [self.speechRecognizer setConfiguration:self.configuration];
    [self.menuBarController setVisible:self.configuration.showMenuBarIcon];
    [self.mainViewController setSidebarVisible:self.configuration.showTelemetry];
    if (self.cinemaActive) [self.cinemaWindowController refreshAppearance];
    if (self.viewerWindowController) [self.viewerWindowController refreshConfiguration];
    [self updateMenuState];
    if (self.inCompactMode) {
        self.mainWindowController.window.level = self.configuration.alwaysOnTop ? NSFloatingWindowLevel : NSNormalWindowLevel;
    }
}

- (void)configurationDidChange:(NSNotification *)notification {
    NSString *key = notification.userInfo[HALConfigurationChangedKeyKey];
    [self applyConfiguration];

    if ([key isEqualToString:@"scenario"]) {
        [self.simulator setScenarioIdentifier:self.configuration.scenario];
        [self.mainViewController refreshSimulator];
    } else if ([key isEqualToString:@"tickRate"]) {
        BOOL wasRunning = self.simulator.isRunning;
        [self.simulator stop];
        self.simulator.tickRate = MAX(0.1, self.configuration.tickRate);
        if (wasRunning) [self.simulator start];
    } else if ([key isEqualToString:@"idleChatter"] || [key isEqualToString:@"idleInterval"]) {
        [self restartIdleTimer];
    } else if ([key isEqualToString:@"launchAtLogin"]) {
        [self applyLaunchAtLoginSetting];
    } else if ([key isEqualToString:@"showMenuBarIcon"]) {
        [self.menuBarController setVisible:self.configuration.showMenuBarIcon];
    }
}

- (void)configurationDidReset:(NSNotification *)notification {
    [self applyConfiguration];
    [self.simulator setScenarioIdentifier:self.configuration.scenario];
    [self.mainViewController refreshSimulator];
    [self restartIdleTimer];
    [self applyLaunchAtLoginSetting];
}

- (void)applyLaunchAtLoginSetting {
    if (self.updatingLaunchAtLogin) return;
    BOOL requested = self.configuration.launchAtLogin;
    NSError *error = nil;
    if ([[HALLaunchAtLogin sharedController] setEnabled:requested error:&error]) return;

    // Never flip the checkbox back to "on" when the user asked for "off".
    // Leaving the requested value in place also stops the failed-unregister
    // path from re-triggering itself on every launch.
    self.updatingLaunchAtLogin = YES;
    if (requested) {
        self.configuration.launchAtLogin = [[HALLaunchAtLogin sharedController] isEnabled];
    } else {
        self.configuration.launchAtLogin = NO;
    }
    self.updatingLaunchAtLogin = NO;

    NSString *detail = error.localizedDescription ?: @"The system could not update the login item.";
    [self showSimpleAlert:@"Launch at login unavailable"
                  message:[detail stringByAppendingString:@" Move HAL 9000 to /Applications and try again. The setting has been left off."]];
}

#pragma mark - Simulator and idle

- (void)simulatorDidUpdate:(NSNotification *)notification {
    [self.mainViewController refreshSimulator];
    if (self.cinemaActive && self.conversationController.state == HALConversationStateIdle) {
        [self.cinemaWindowController setStatus:[self currentStatusText]];
    }
}

- (void)restartIdleTimer {
    [self.idleTimer invalidate];
    self.idleTimer = nil;
    if (!self.configuration.idleChatter) return;
    NSTimeInterval interval = MAX(30.0, self.configuration.idleInterval);
    self.idleTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                      target:self
                                                    selector:@selector(idleTimerFired:)
                                                    userInfo:nil
                                                     repeats:YES];
}

- (void)idleTimerFired:(NSTimer *)timer {
    if (self.bootController || self.safeMode) return;
    if (!NSApp.isActive) return;
    if (self.conversationController.isBusy || self.speechSynthesizer.isSpeaking) return;
    if (self.speechRecognizer.isListening) return;
    if (self.cinemaActive) return;
    [self.conversationController emitIdleObservation];
}

#pragma mark - Utilities

- (void)showSimpleAlert:(NSString *)title message:(NSString *)message {
    [NSApp activateIgnoringOtherApps:YES];
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = title ?: @"HAL 9000";
    alert.informativeText = message ?: @"";
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (void)showPrivacyAlertWithMessage:(NSString *)message {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Microphone access is needed";
    alert.informativeText = message.length ? message : @"Text input still works. Enable microphone and speech recognition in System Settings to use voice input.";
    [alert addButtonWithTitle:@"Open Privacy Settings"];
    [alert addButtonWithTitle:@"Not Now"];
    alert.alertStyle = NSAlertStyleWarning;
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        NSURL *url = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"];
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}

- (void)clearConversation:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Clear the conversation?";
    alert.informativeText = @"This removes the local transcript. It cannot be undone.";
    [alert addButtonWithTitle:@"Clear"];
    [alert addButtonWithTitle:@"Cancel"];
    alert.alertStyle = NSAlertStyleWarning;
    if ([alert runModal] != NSAlertFirstButtonReturn) return;
    [self.conversationController clearConversation];
    [self.mainViewController clearTranscript];
    self.lastHALText = @"";
    if (self.cinemaActive) [self.cinemaWindowController setSubtitle:@""];
    [self.mainViewController setStatusText:@"CONVERSATION CLEARED"];
}

- (void)exportTranscript:(id)sender {
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.nameFieldStringValue = @"HAL9000-transcript.md";
    panel.allowedContentTypes = @[[UTType typeWithFilenameExtension:@"md"]];
    __weak typeof(self) weakSelf = self;
    [panel beginSheetModalForWindow:self.mainWindowController.window completionHandler:^(NSModalResponse result) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || result != NSModalResponseOK) return;
        NSError *error = nil;
        if (![[self.memoryStore exportMarkdown] writeToURL:panel.URL atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
            [self showSimpleAlert:@"Could not export transcript" message:error.localizedDescription ?: @"Unknown error."];
        }
    }];
}

- (void)terminateFromMenu:(id)sender {
    [NSApp terminate:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.idleTimer invalidate];
    [self.rearmTimer invalidate];
}

@end
