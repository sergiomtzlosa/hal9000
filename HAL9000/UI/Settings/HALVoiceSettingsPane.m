#import "HALVoiceSettingsPane.h"
#import "HALConfiguration.h"
#import "HALSpeechSynthesizer.h"
#import "HALTheme.h"
#import <AVFoundation/AVFoundation.h>

@interface HALVoiceSettingsPane ()
@property (nonatomic, strong) HALSpeechSynthesizer *speechSynthesizer;
@property (nonatomic, strong) NSTextField *statusLabel;
@property (nonatomic, strong) NSSlider *rateSlider;
@property (nonatomic, strong) NSSlider *pitchSlider;
@property (nonatomic, strong) NSTextField *rateValue;
@property (nonatomic, strong) NSTextField *pitchValue;
@property (nonatomic, strong) NSPopUpButton *voicePopup;
@end

@implementation HALVoiceSettingsPane

- (instancetype)initWithConfiguration:(HALConfiguration *)configuration
                  speechSynthesizer:(HALSpeechSynthesizer *)speechSynthesizer {
    self = [super initWithConfiguration:configuration];
    if (self) {
        _speechSynthesizer = speechSynthesizer;
    }
    return self;
}

- (void)loadView {
    NSStackView *stack = [self scrollableStack];
    [stack addArrangedSubview:[self sectionTitle:@"Voice"]];
    [stack addArrangedSubview:[self helpText:@"HAL uses the system speech synthesizer. Voice quality depends on the voices installed in macOS."]];

    self.voicePopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    self.voicePopup.translatesAutoresizingMaskIntoConstraints = NO;
    self.voicePopup.identifier = @"voiceIdentifier";
    self.voicePopup.font = [HALTheme uiFontOfSize:12 weight:NSFontWeightRegular];
    self.voicePopup.target = self;
    self.voicePopup.action = @selector(popupChanged:);
    [self.voicePopup addItemWithTitle:@"System default"];
    self.voicePopup.lastItem.representedObject = @"";
    NSString *savedVoice = self.configuration.voiceIdentifier ?: @"";
    if (savedVoice.length > 0) {
        [self.voicePopup addItemWithTitle:@"Saved voice"];
        self.voicePopup.lastItem.representedObject = savedVoice;
        [self.voicePopup selectItem:self.voicePopup.lastItem];
    }
    [self.voicePopup addItemWithTitle:@"Loading installed voices…"];
    self.voicePopup.lastItem.enabled = NO;
    [self.voicePopup.widthAnchor constraintEqualToConstant:300].active = YES;
    [stack addArrangedSubview:[self rowWithLabel:@"Voice" control:self.voicePopup]];

    // Enumerating every installed system voice can take several hundred
    // milliseconds on first use. Do it off the main thread so opening the
    // Voice pane never stalls the control room.
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        NSMutableArray<NSDictionary *> *voiceOptions = [NSMutableArray array];
        for (AVSpeechSynthesisVoice *voice in [self.speechSynthesizer availableVoices]) {
            [voiceOptions addObject:@{
                @"title": [self.speechSynthesizer displayNameForVoice:voice],
                @"value": voice.identifier ?: @""
            }];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            [self populateVoicePopup:voiceOptions];
        });
    });

    NSPopUpButton *character = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    character.translatesAutoresizingMaskIntoConstraints = NO;
    character.font = [HALTheme uiFontOfSize:12 weight:NSFontWeightRegular];
    NSArray *characters = @[@[@"Classic — slower and lower", @"classic"],
                            @[@"Calm — quiet and measured", @"calm"],
                            @[@"Precise — faster and clearer", @"precise"],
                            @[@"Custom — use sliders", @"custom"]];
    for (NSArray *entry in characters) {
        [character addItemWithTitle:entry[0]];
        character.lastItem.representedObject = entry[1];
        if ([entry[1] isEqualToString:self.configuration.voiceCharacter]) [character selectItem:character.lastItem];
    }
    character.target = self;
    character.action = @selector(characterChanged:);
    [character.widthAnchor constraintEqualToConstant:300].active = YES;
    [stack addArrangedSubview:[self rowWithLabel:@"Character" control:character]];

    self.rateSlider = [self sliderWithKey:@"voiceRate" minimum:0.0 maximum:1.0];
    self.rateValue = [self valueLabelForSlider:self.rateSlider];
    [stack addArrangedSubview:[self rowWithLabel:@"Rate" control:self.rateSlider valueLabel:self.rateValue]];
    self.pitchSlider = [self sliderWithKey:@"voicePitch" minimum:0.5 maximum:2.0];
    self.pitchValue = [self valueLabelForSlider:self.pitchSlider];
    [stack addArrangedSubview:[self rowWithLabel:@"Pitch" control:self.pitchSlider valueLabel:self.pitchValue]];
    [self addSliderRowWithKey:@"voiceVolume" label:@"Volume" minimum:0.0 maximum:1.0];

    NSTextField *previewText = [self textFieldWithKey:@"previewText" placeholder:@"Good morning, Dave."];
    [stack addArrangedSubview:[self rowWithLabel:@"Preview text" control:previewText]];

    NSStackView *buttons = [NSStackView stackViewWithViews:@[
        [self buttonWithTitle:@"Preview Voice" action:@selector(previewPressed:)],
        [self buttonWithTitle:@"Stop" action:@selector(stopPressed:)]
    ]];
    buttons.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    buttons.spacing = 8;
    [stack addArrangedSubview:buttons];

    self.statusLabel = [self helpText:@" "];
    [stack addArrangedSubview:self.statusLabel];

    [stack addArrangedSubview:[self checkboxWithTitle:@"Speak every HAL reply" key:@"autoSpeak"]];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Stop current speech when a new message is sent" key:@"stopOnNewMessage"]];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Speak the final boot line" key:@"speakBootLine"]];
}

- (void)populateVoicePopup:(NSArray<NSDictionary *> *)options {
    if (!self.voicePopup) return;
    NSString *selected = self.configuration.voiceIdentifier ?: @"";
    [self.voicePopup removeAllItems];
    [self.voicePopup addItemWithTitle:@"System default"];
    self.voicePopup.lastItem.representedObject = @"";
    for (NSDictionary *option in options) {
        [self.voicePopup addItemWithTitle:option[@"title"]];
        self.voicePopup.lastItem.representedObject = option[@"value"];
    }
    BOOL matched = NO;
    for (NSMenuItem *item in self.voicePopup.itemArray) {
        if ([item.representedObject isEqualToString:selected]) {
            [self.voicePopup selectItem:item];
            matched = YES;
            break;
        }
    }
    if (!matched) [self.voicePopup selectItemAtIndex:0];
}

- (void)characterChanged:(NSPopUpButton *)sender {
    NSString *character = sender.selectedItem.representedObject;
    self.configuration.voiceCharacter = character;
    if ([character isEqualToString:@"classic"]) {
        self.configuration.voiceRate = 0.42;
        self.configuration.voicePitch = 0.82;
    } else if ([character isEqualToString:@"calm"]) {
        self.configuration.voiceRate = 0.38;
        self.configuration.voicePitch = 0.90;
    } else if ([character isEqualToString:@"precise"]) {
        self.configuration.voiceRate = 0.48;
        self.configuration.voicePitch = 0.95;
    }
    self.rateSlider.doubleValue = self.configuration.voiceRate;
    self.pitchSlider.doubleValue = self.configuration.voicePitch;
    self.rateValue.stringValue = [NSString stringWithFormat:@"%.2f", self.configuration.voiceRate];
    self.pitchValue.stringValue = [NSString stringWithFormat:@"%.2f", self.configuration.voicePitch];
}

- (void)previewPressed:(id)sender {
    NSString *text = self.configuration.previewText.length ? self.configuration.previewText : @"Good morning, Dave.";
    self.statusLabel.stringValue = @"Previewing…";
    __weak typeof(self) weakSelf = self;
    [self.speechSynthesizer previewText:text completion:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.statusLabel.stringValue = @"Preview complete.";
    }];
}

- (void)stopPressed:(id)sender {
    [self.speechSynthesizer stop];
    self.statusLabel.stringValue = @"Speech stopped.";
}

@end
