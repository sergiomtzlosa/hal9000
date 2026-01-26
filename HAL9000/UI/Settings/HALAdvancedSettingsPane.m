#import "HALAdvancedSettingsPane.h"
#import "HALConfiguration.h"
#import "HALMemoryStore.h"
#import "HALShipSimulator.h"
#import "HALSpeechSynthesizer.h"
#import "HALSpeechRecognizer.h"
#import "HALKeychainStore.h"
#import "HALTheme.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <Speech/Speech.h>

@interface HALAdvancedSettingsPane ()
@property (nonatomic, strong) HALMemoryStore *memoryStore;
@property (nonatomic, strong) HALShipSimulator *simulator;
@property (nonatomic, strong) HALSpeechSynthesizer *speechSynthesizer;
@property (nonatomic, strong) HALSpeechRecognizer *recognizer;
@property (nonatomic, strong) NSTextField *statusLabel;
@property (nonatomic, strong) NSTextView *diagnosticsView;
@end

@implementation HALAdvancedSettingsPane

- (instancetype)initWithConfiguration:(HALConfiguration *)configuration
                          memoryStore:(HALMemoryStore *)memoryStore
                            simulator:(HALShipSimulator *)simulator
                  speechSynthesizer:(HALSpeechSynthesizer *)speechSynthesizer
                         recognizer:(HALSpeechRecognizer *)recognizer {
    self = [super initWithConfiguration:configuration];
    if (self) {
        _memoryStore = memoryStore;
        _simulator = simulator;
        _speechSynthesizer = speechSynthesizer;
        _recognizer = recognizer;
    }
    return self;
}

- (NSURL *)supportDirectory {
    NSURL *base = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] firstObject];
    return [base URLByAppendingPathComponent:@"HAL9000" isDirectory:YES];
}

- (void)loadView {
    NSStackView *stack = [self scrollableStack];
    [stack addArrangedSubview:[self sectionTitle:@"Data & Settings"]];
    [stack addArrangedSubview:[self helpText:@"Settings export excludes Keychain secrets. Transcripts are local files and are never uploaded."]];

    NSStackView *settingsButtons = [NSStackView stackViewWithViews:@[
        [self buttonWithTitle:@"Export Settings…" action:@selector(exportSettings:)],
        [self buttonWithTitle:@"Import Settings…" action:@selector(importSettings:)]
    ]];
    settingsButtons.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    settingsButtons.spacing = 8;
    [stack addArrangedSubview:settingsButtons];

    NSStackView *transcriptButtons = [NSStackView stackViewWithViews:@[
        [self buttonWithTitle:@"Export Transcript (Markdown)…" action:@selector(exportMarkdown:)],
        [self buttonWithTitle:@"Export Transcript (JSON)…" action:@selector(exportJSON:)]
    ]];
    transcriptButtons.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    transcriptButtons.spacing = 8;
    [stack addArrangedSubview:transcriptButtons];

    [stack addArrangedSubview:[self buttonWithTitle:@"Clear Conversation…" action:@selector(clearConversation:)]];
    [stack addArrangedSubview:[self buttonWithTitle:@"Reset All Settings…" action:@selector(resetAllSettings:)]];
    NSStackView *folderButtons = [NSStackView stackViewWithViews:@[
        [self buttonWithTitle:@"Reveal Application Support" action:@selector(revealSupportFolder:)],
        [self buttonWithTitle:@"Open Logs" action:@selector(openLogs:)]
    ]];
    folderButtons.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    folderButtons.spacing = 8;
    [stack addArrangedSubview:folderButtons];

    [stack addArrangedSubview:[self sectionTitle:@"Diagnostics"]];
    self.diagnosticsView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 500, 220)];
    self.diagnosticsView.editable = NO;
    self.diagnosticsView.selectable = YES;
    self.diagnosticsView.drawsBackground = YES;
    self.diagnosticsView.backgroundColor = [HALTheme colorFromHex:@"#0A0C0E"];
    self.diagnosticsView.textColor = [HALTheme secondaryText];
    self.diagnosticsView.font = [HALTheme monoFontOfSize:10 weight:NSFontWeightRegular];
    self.diagnosticsView.textContainerInset = NSMakeSize(10, 10);
    NSScrollView *diagnosticsScroll = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    diagnosticsScroll.translatesAutoresizingMaskIntoConstraints = NO;
    diagnosticsScroll.hasVerticalScroller = YES;
    diagnosticsScroll.borderType = NSBezelBorder;
    diagnosticsScroll.documentView = self.diagnosticsView;
    [diagnosticsScroll.heightAnchor constraintEqualToConstant:220].active = YES;
    [diagnosticsScroll.widthAnchor constraintEqualToConstant:500].active = YES;
    [stack addArrangedSubview:diagnosticsScroll];

    NSStackView *diagnosticButtons = [NSStackView stackViewWithViews:@[
        [self buttonWithTitle:@"Refresh Diagnostics" action:@selector(refreshDiagnostics:)],
        [self buttonWithTitle:@"Copy Diagnostics" action:@selector(copyDiagnostics:)]
    ]];
    diagnosticButtons.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    diagnosticButtons.spacing = 8;
    [stack addArrangedSubview:diagnosticButtons];
    self.statusLabel = [self helpText:@" "];
    [stack addArrangedSubview:self.statusLabel];
    [self refreshDiagnostics:nil];
}

- (void)exportSettings:(id)sender {
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.nameFieldStringValue = @"HAL9000-settings.json";
    panel.allowedContentTypes = @[UTTypeJSON];
    __weak typeof(self) weakSelf = self;
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || result != NSModalResponseOK) return;
        NSDictionary *settings = [self.configuration exportSettings];
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:settings options:NSJSONWritingPrettyPrinted error:&error];
        if (!data || ![data writeToURL:panel.URL options:NSDataWritingAtomic error:&error]) {
            [self showError:error.localizedDescription ?: @"Could not export settings."];
            return;
        }
        self.statusLabel.stringValue = @"Settings exported. The API key was not included.";
        self.statusLabel.textColor = [HALTheme success];
    }];
}

- (void)importSettings:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowedContentTypes = @[UTTypeJSON];
    panel.allowsMultipleSelection = NO;
    __weak typeof(self) weakSelf = self;
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || result != NSModalResponseOK) return;
        NSError *error = nil;
        NSData *data = [NSData dataWithContentsOfURL:panel.URL options:0 error:&error];
        id object = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
        if (![object isKindOfClass:[NSDictionary class]] || ![self.configuration importSettings:object error:&error]) {
            [self showError:error.localizedDescription ?: @"The settings file could not be imported."];
            return;
        }
        self.statusLabel.stringValue = @"Settings imported. The API key is unchanged.";
        self.statusLabel.textColor = [HALTheme success];
    }];
}

- (void)exportMarkdown:(id)sender {
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.nameFieldStringValue = @"HAL9000-transcript.md";
    panel.allowedContentTypes = @[[UTType typeWithFilenameExtension:@"md"]];
    __weak typeof(self) weakSelf = self;
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || result != NSModalResponseOK) return;
        NSError *error = nil;
        if (![[self.memoryStore exportMarkdown] writeToURL:panel.URL atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
            [self showError:error.localizedDescription ?: @"Could not export the transcript."];
            return;
        }
        self.statusLabel.stringValue = @"Transcript exported as Markdown.";
        self.statusLabel.textColor = [HALTheme success];
    }];
}

- (void)exportJSON:(id)sender {
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.nameFieldStringValue = @"HAL9000-transcript.json";
    panel.allowedContentTypes = @[UTTypeJSON];
    __weak typeof(self) weakSelf = self;
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || result != NSModalResponseOK) return;
        NSError *error = nil;
        NSData *data = [self.memoryStore exportJSONData:&error];
        if (!data || ![data writeToURL:panel.URL options:NSDataWritingAtomic error:&error]) {
            [self showError:error.localizedDescription ?: @"Could not export the transcript."];
            return;
        }
        self.statusLabel.stringValue = @"Transcript exported as JSON.";
        self.statusLabel.textColor = [HALTheme success];
    }];
}

- (void)clearConversation:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Clear the conversation?";
    alert.informativeText = @"This removes the transcript from Application Support. It cannot be undone.";
    [alert addButtonWithTitle:@"Clear"];
    [alert addButtonWithTitle:@"Cancel"];
    alert.alertStyle = NSAlertStyleWarning;
    if ([alert runModal] != NSAlertFirstButtonReturn) return;
    [self.memoryStore clearMessages];
    if (self.onClearConversation) self.onClearConversation();
    self.statusLabel.stringValue = @"Conversation cleared.";
    self.statusLabel.textColor = [HALTheme success];
}

- (void)resetAllSettings:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Reset all settings?";
    alert.informativeText = @"This restores every configuration option to its default. Transcripts and the Keychain API key are not removed.";
    [alert addButtonWithTitle:@"Reset"];
    [alert addButtonWithTitle:@"Cancel"];
    alert.alertStyle = NSAlertStyleWarning;
    if ([alert runModal] != NSAlertFirstButtonReturn) return;
    [self.configuration resetToDefaults];
    self.statusLabel.stringValue = @"All settings reset to defaults.";
    self.statusLabel.textColor = [HALTheme success];
}

- (void)revealSupportFolder:(id)sender {
    [self supportDirectory];
    [[NSWorkspace sharedWorkspace] openURL:[self supportDirectory]];
}

- (void)openLogs:(id)sender {
    NSURL *logs = [[self supportDirectory] URLByAppendingPathComponent:@"logs" isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtURL:logs withIntermediateDirectories:YES attributes:nil error:NULL];
    [[NSWorkspace sharedWorkspace] openURL:logs];
}

- (NSString *)diagnosticsText {
    NSMutableString *text = [NSMutableString string];
    NSDictionary *info = [NSBundle mainBundle].infoDictionary;
    [text appendFormat:@"HAL 9000 %@ (%@)\n", info[@"CFBundleShortVersionString"] ?: @"1.0", info[@"CFBundleVersion"] ?: @"1"];
    [text appendFormat:@"macOS: %@\n", [NSProcessInfo processInfo].operatingSystemVersionString];
    [text appendFormat:@"Engine: %@\n", self.configuration.engine];
    [text appendFormat:@"Base URL: %@\n", self.configuration.baseURL.length ? self.configuration.baseURL : @"(not set)"];
    [text appendFormat:@"Model: %@\n", self.configuration.model.length ? self.configuration.model : @"(not set)"];
    [text appendFormat:@"API key: %@\n", [[HALKeychainStore sharedStore] hasAPIKey] ? @"present (Keychain)" : @"not set"];
    [text appendFormat:@"Scenario: %@\n", self.simulator.scenario.name];
    [text appendFormat:@"Warnings: %ld\n", (long)[self.simulator warningCount]];
    NSInteger voiceCount = self.speechSynthesizer.cachedVoiceCount;
    [text appendFormat:@"Available voices: %@\n", voiceCount < 0 ? @"loading in background" : [NSString stringWithFormat:@"%ld", (long)voiceCount]];
    [text appendFormat:@"Speech recognition: %@\n", [self speechAuthorizationLabel]];
    [text appendFormat:@"Recent events:\n%@\n", [self.simulator recentEventsSummary]];
    [text appendFormat:@"Support: %@\n", [self supportDirectory].path];
    return text;
}

- (NSString *)speechAuthorizationLabel {
    switch ([SFSpeechRecognizer authorizationStatus]) {
        case SFSpeechRecognizerAuthorizationStatusAuthorized: return @"authorized";
        case SFSpeechRecognizerAuthorizationStatusDenied: return @"denied";
        case SFSpeechRecognizerAuthorizationStatusRestricted: return @"restricted";
        case SFSpeechRecognizerAuthorizationStatusNotDetermined: return @"not determined";
    }
}

- (void)refreshDiagnostics:(id)sender {
    self.diagnosticsView.string = [self diagnosticsText];
}

- (void)copyDiagnostics:(id)sender {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard setString:[self diagnosticsText] forType:NSPasteboardTypeString];
    self.statusLabel.stringValue = @"Diagnostics copied to the clipboard.";
    self.statusLabel.textColor = [HALTheme success];
}

- (void)showError:(NSString *)message {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"HAL 9000";
    alert.informativeText = message;
    alert.alertStyle = NSAlertStyleWarning;
    [alert runModal];
}

@end
