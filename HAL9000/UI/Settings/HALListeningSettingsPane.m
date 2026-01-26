#import "HALListeningSettingsPane.h"
#import "HALConfiguration.h"
#import "HALSpeechRecognizer.h"
#import "HALTheme.h"
#import <Speech/Speech.h>

@interface HALListeningSettingsPane ()
@property (nonatomic, strong) HALSpeechRecognizer *recognizer;
@property (nonatomic, strong) NSTextField *permissionLabel;
@end

@implementation HALListeningSettingsPane

- (instancetype)initWithConfiguration:(HALConfiguration *)configuration
                           recognizer:(HALSpeechRecognizer *)recognizer {
    self = [super initWithConfiguration:configuration];
    if (self) {
        _recognizer = recognizer;
    }
    return self;
}

- (void)loadView {
    NSStackView *stack = [self scrollableStack];
    [stack addArrangedSubview:[self sectionTitle:@"Listening"]];
    [stack addArrangedSubview:[self helpText:@"Text input always works. Microphone access is requested only when you listen for the first time."]];

    [stack addArrangedSubview:[self checkboxWithTitle:@"Enable voice input" key:@"listeningEnabled"]];
    NSPopUpButton *mode = [self popupWithKey:@"listeningMode" options:@[
        @{@"title": @"Push to talk", @"value": @"pushToTalk"},
        @{@"title": @"Wake phrase", @"value": @"wakeWord"},
        @{@"title": @"Off", @"value": @"off"}
    ]];
    [stack addArrangedSubview:[self rowWithLabel:@"Mode" control:mode]];

    NSTextField *wake = [self textFieldWithKey:@"wakePhrase" placeholder:@"HAL"];
    [stack addArrangedSubview:[self rowWithLabel:@"Wake phrase" control:wake]];

    NSMutableArray *localeOptions = [NSMutableArray array];
    NSMutableArray *locales = [[[SFSpeechRecognizer supportedLocales] allObjects] mutableCopy];
    [locales sortUsingComparator:^NSComparisonResult(NSLocale *a, NSLocale *b) {
        return [a.localeIdentifier compare:b.localeIdentifier];
    }];
    for (NSLocale *locale in locales) {
        NSString *identifier = locale.localeIdentifier;
        NSLocale *current = [NSLocale currentLocale];
        NSString *name = [current displayNameForKey:NSLocaleIdentifier value:identifier] ?: identifier;
        [localeOptions addObject:@{@"title": [NSString stringWithFormat:@"%@ (%@)", name, identifier], @"value": identifier}];
    }
    if (localeOptions.count == 0) {
        [localeOptions addObject:@{@"title": @"en-US", @"value": @"en-US"}];
    }
    NSPopUpButton *localePopup = [self popupWithKey:@"speechLocale" options:localeOptions];
    [stack addArrangedSubview:[self rowWithLabel:@"Recognition locale" control:localePopup]];

    [self addSliderRowWithKey:@"silenceTimeout" label:@"Silence timeout (s)" minimum:0.5 maximum:3.0];
    [self addSliderRowWithKey:@"maxUtterance" label:@"Maximum utterance (s)" minimum:3.0 maximum:30.0];

    [stack addArrangedSubview:[self checkboxWithTitle:@"Send the final transcript automatically" key:@"autoSend"]];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Prefer on-device recognition when available" key:@"onDevicePreferred"]];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Play a subtle start/stop cue" key:@"playCue"]];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Re-arm after each reply (wake-word mode)" key:@"continuousListening"]];

    [stack addArrangedSubview:[self sectionTitle:@"Permissions"]];
    self.permissionLabel = [self helpText:@"Permission status is checked on demand."];
    [stack addArrangedSubview:self.permissionLabel];
    NSStackView *buttons = [NSStackView stackViewWithViews:@[
        [self buttonWithTitle:@"Check Permissions" action:@selector(checkPermissions:)],
        [self buttonWithTitle:@"Open Privacy Settings" action:@selector(openPrivacySettings:)]
    ]];
    buttons.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    buttons.spacing = 8;
    [stack addArrangedSubview:buttons];
}

- (void)checkPermissions:(id)sender {
    self.permissionLabel.stringValue = @"Requesting permission status…";
    __weak typeof(self) weakSelf = self;
    [self.recognizer requestPermissionsWithCompletion:^(BOOL granted, NSString *status) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.permissionLabel.stringValue = status;
        self.permissionLabel.textColor = granted ? [HALTheme success] : [HALTheme warning];
    }];
}

- (void)openPrivacySettings:(id)sender {
    NSURL *url = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

@end
