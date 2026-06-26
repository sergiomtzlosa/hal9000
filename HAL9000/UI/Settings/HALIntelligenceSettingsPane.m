#import "HALIntelligenceSettingsPane.h"
#import "HALConfiguration.h"
#import "HALKeychainStore.h"
#import "HALLLMClient.h"
#import "HALTheme.h"

@interface HALIntelligenceSettingsPane ()
@property (nonatomic, strong) NSPopUpButton *enginePopup;
@property (nonatomic, strong) NSSecureTextField *apiKeyField;
@property (nonatomic, strong) NSTextField *statusLabel;
@property (nonatomic, strong) HALLLMClient *testClient;
@end

@implementation HALIntelligenceSettingsPane

- (void)loadView {
    NSStackView *stack = [self scrollableStack];
    [stack addArrangedSubview:[self sectionTitle:@"Intelligence"]];
    [stack addArrangedSubview:[self helpText:@"Optional. HAL is fully conversational offline. Connect an OpenAI-compatible endpoint or a local Ollama server for open-ended replies."]];

    self.enginePopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    self.enginePopup.translatesAutoresizingMaskIntoConstraints = NO;
    self.enginePopup.font = [HALTheme uiFontOfSize:12 weight:NSFontWeightRegular];
    NSArray *engines = @[@[@"Scripted (offline)", @"scripted"],
                         @[@"OpenAI-compatible", @"openAICompatible"],
                         @[@"Ollama / local", @"ollama"]];
    for (NSArray *entry in engines) {
        [self.enginePopup addItemWithTitle:entry[0]];
        self.enginePopup.lastItem.representedObject = entry[1];
        if ([entry[1] isEqualToString:self.configuration.engine]) [self.enginePopup selectItem:self.enginePopup.lastItem];
    }
    self.enginePopup.target = self;
    self.enginePopup.action = @selector(engineChanged:);
    [self.enginePopup.widthAnchor constraintEqualToConstant:260].active = YES;
    [stack addArrangedSubview:[self rowWithLabel:@"Engine" control:self.enginePopup]];

    NSTextField *baseURL = [self textFieldWithKey:@"baseURL" placeholder:@"http://localhost:11434/v1"];
    [stack addArrangedSubview:[self rowWithLabel:@"Base URL" control:baseURL]];
    NSTextField *model = [self textFieldWithKey:@"model" placeholder:@"llama3.2"];
    [stack addArrangedSubview:[self rowWithLabel:@"Model" control:model]];

    self.apiKeyField = [[NSSecureTextField alloc] initWithFrame:NSZeroRect];
    self.apiKeyField.translatesAutoresizingMaskIntoConstraints = NO;
    self.apiKeyField.font = [HALTheme uiFontOfSize:12 weight:NSFontWeightRegular];
    self.apiKeyField.textColor = [HALTheme text];
    self.apiKeyField.backgroundColor = [HALTheme colorFromHex:@"#101316"];
    self.apiKeyField.bezelStyle = NSTextFieldSquareBezel;
    self.apiKeyField.focusRingType = NSFocusRingTypeNone;
    self.apiKeyField.placeholderString = [[HALKeychainStore sharedStore] hasAPIKey] ? @"•••••••••••• (saved in Keychain)" : @"Optional for local endpoints";
    [self.apiKeyField.widthAnchor constraintEqualToConstant:300].active = YES;
    [stack addArrangedSubview:[self rowWithLabel:@"API key" control:self.apiKeyField]];

    NSStackView *keyButtons = [NSStackView stackViewWithViews:@[
        [self buttonWithTitle:@"Save Key" action:@selector(saveKey:)],
        [self buttonWithTitle:@"Clear Key" action:@selector(clearKey:)],
        [self buttonWithTitle:@"Test Connection" action:@selector(testConnection:)]
    ]];
    keyButtons.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    keyButtons.spacing = 8;
    [stack addArrangedSubview:keyButtons];
    self.statusLabel = [self helpText:@"The API key is stored only in the macOS Keychain and is never exported or logged."];
    [stack addArrangedSubview:self.statusLabel];

    [self addSliderRowWithKey:@"temperature" label:@"Temperature" minimum:0.0 maximum:2.0];
    [self addSliderRowWithKey:@"maxTokens" label:@"Max tokens" minimum:64 maximum:2048];
    [self addSliderRowWithKey:@"timeout" label:@"Timeout (s)" minimum:5.0 maximum:120.0];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Stream responses (SSE)" key:@"streamResponses"]];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Fall back to scripted mode on errors" key:@"fallbackToScripted"]];
    NSTextField *override = [self multilineTextFieldWithKey:@"systemPromptOverride" height:110];
    [stack addArrangedSubview:[self rowWithLabel:@"System prompt override" control:override]];
    [stack addArrangedSubview:[self helpText:@"The override replaces the generated personality block but keeps the safety constraint and simulation context."]];
    [stack addArrangedSubview:[self buttonWithTitle:@"Use Offline Mode" action:@selector(useOfflineMode:)]];
}

- (void)engineChanged:(NSPopUpButton *)sender {
    self.configuration.engine = sender.selectedItem.representedObject;
}

- (void)saveKey:(id)sender {
    NSString *key = [self.apiKeyField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (key.length == 0) {
        self.statusLabel.stringValue = @"Enter an API key first, or use Clear Key.";
        self.statusLabel.textColor = [HALTheme warning];
        return;
    }
    NSError *error = nil;
    if ([[HALKeychainStore sharedStore] saveAPIKey:key error:&error]) {
        self.apiKeyField.stringValue = @"";
        self.apiKeyField.placeholderString = @"•••••••••••• (saved in Keychain)";
        self.statusLabel.stringValue = @"API key saved in the Keychain.";
        self.statusLabel.textColor = [HALTheme success];
    } else {
        self.statusLabel.stringValue = error.localizedDescription;
        self.statusLabel.textColor = [HALTheme warning];
    }
}

- (void)clearKey:(id)sender {
    NSError *error = nil;
    if ([[HALKeychainStore sharedStore] deleteAPIKey:&error]) {
        self.apiKeyField.stringValue = @"";
        self.apiKeyField.placeholderString = @"No key stored";
        self.statusLabel.stringValue = @"API key removed from the Keychain.";
        self.statusLabel.textColor = [HALTheme secondaryText];
    } else {
        self.statusLabel.stringValue = error.localizedDescription;
        self.statusLabel.textColor = [HALTheme warning];
    }
}

- (void)testConnection:(id)sender {
    if ([self.configuration.engine isEqualToString:@"scripted"]) {
        self.statusLabel.stringValue = @"Select OpenAI-compatible or Ollama first.";
        self.statusLabel.textColor = [HALTheme warning];
        return;
    }
    if (self.configuration.baseURL.length == 0 || self.configuration.model.length == 0) {
        self.statusLabel.stringValue = @"Set a base URL and model first.";
        self.statusLabel.textColor = [HALTheme warning];
        return;
    }
    NSError *keyError = nil;
    NSString *key = [[HALKeychainStore sharedStore] apiKey:&keyError];
    if (keyError) {
        self.statusLabel.stringValue = keyError.localizedDescription;
        self.statusLabel.textColor = [HALTheme warning];
        return;
    }
    self.statusLabel.stringValue = @"Testing connection…";
    self.statusLabel.textColor = [HALTheme secondaryText];
    HALLLMClient *client = [[HALLLMClient alloc] initWithConfiguration:self.configuration apiKey:key];
    self.testClient = client;
    NSArray *messages = @[
        @{@"role": @"system", @"content": @"You are HAL 9000. Reply with one short, calm sentence."},
        @{@"role": @"user", @"content": @"Connection test."}
    ];
    __weak typeof(self) weakSelf = self;
    [client streamMessages:messages onDelta:^(NSString *delta) {
    } completion:^(NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.testClient = nil;
        if (error) {
            self.statusLabel.stringValue = [NSString stringWithFormat:@"Connection failed: %@", error.localizedDescription];
            self.statusLabel.textColor = [HALTheme warning];
        } else {
            self.statusLabel.stringValue = @"Connection successful. HAL's higher functions are available.";
            self.statusLabel.textColor = [HALTheme success];
        }
    }];
}

- (void)useOfflineMode:(id)sender {
    self.configuration.engine = @"scripted";
    for (NSMenuItem *item in self.enginePopup.itemArray) {
        if ([item.representedObject isEqualToString:@"scripted"]) {
            [self.enginePopup selectItem:item];
            break;
        }
    }
    self.statusLabel.stringValue = @"Offline scripted mode enabled.";
    self.statusLabel.textColor = [HALTheme success];
}

@end
