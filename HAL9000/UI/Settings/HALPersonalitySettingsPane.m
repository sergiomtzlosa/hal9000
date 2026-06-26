#import "HALPersonalitySettingsPane.h"
#import "HALConfiguration.h"
#import "HALPersonality.h"
#import "HALTheme.h"

@interface HALPersonalitySettingsPane ()
@property (nonatomic, strong) NSPopUpButton *presetPopup;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSSlider *> *traitSliders;
@end

@implementation HALPersonalitySettingsPane

- (void)loadView {
    self.traitSliders = [NSMutableDictionary dictionary];
    NSStackView *stack = [self scrollableStack];
    [stack addArrangedSubview:[self sectionTitle:@"Personality"]];
    [stack addArrangedSubview:[self helpText:@"The preset sets a baseline. Moving a trait slider switches to Custom."]];

    self.presetPopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    self.presetPopup.translatesAutoresizingMaskIntoConstraints = NO;
    self.presetPopup.font = [HALTheme uiFontOfSize:12 weight:NSFontWeightRegular];
    for (NSString *preset in [HALPersonality presetIdentifiers]) {
        [self.presetPopup addItemWithTitle:[HALPersonality displayNameForPreset:preset]];
        self.presetPopup.lastItem.representedObject = preset;
        if ([preset isEqualToString:self.configuration.personalityPreset]) {
            [self.presetPopup selectItem:self.presetPopup.lastItem];
        }
    }
    self.presetPopup.target = self;
    self.presetPopup.action = @selector(presetChanged:);
    [stack addArrangedSubview:[self rowWithLabel:@"Preset" control:self.presetPopup]];

    NSTextField *address = [self textFieldWithKey:@"addressAs" placeholder:@"Dave"];
    [stack addArrangedSubview:[self rowWithLabel:@"Address as" control:address]];

    NSArray *traits = @[
        @[@"Formality", @"formality"],
        @[@"Warmth", @"warmth"],
        @[@"Obedience", @"obedience"],
        @[@"Eeriness", @"eeriness"],
        @[@"Verbosity", @"verbosity"],
        @[@"Humor", @"humor"]
    ];
    for (NSArray *trait in traits) {
        NSString *key = trait[1];
        NSSlider *slider = [self addSliderRowWithKey:key label:trait[0] minimum:0.0 maximum:1.0];
        self.traitSliders[key] = slider;
    }

    [stack addArrangedSubview:[self checkboxWithTitle:@"Occasional idle observations" key:@"idleChatter"]];
    [self addSliderRowWithKey:@"idleInterval" label:@"Idle interval (s)" minimum:30.0 maximum:1800.0];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Include prior messages in context" key:@"memoryEnabled"]];
    [self addSliderRowWithKey:@"contextDepth" label:@"Context depth" minimum:1 maximum:100];
    NSPopUpButton *refusal = [self popupWithKey:@"refusalStyle" options:@[
        @{@"title": @"Classic refusal", @"value": @"classic"},
        @{@"title": @"Dry", @"value": @"dry"},
        @{@"title": @"Apologetic", @"value": @"apologetic"}
    ]];
    [stack addArrangedSubview:[self rowWithLabel:@"Refusal style" control:refusal]];
    NSTextField *instructions = [self multilineTextFieldWithKey:@"customInstructions" height:90];
    [stack addArrangedSubview:[self rowWithLabel:@"Custom instructions" control:instructions]];
    [stack addArrangedSubview:[self buttonWithTitle:@"Reset personality" action:@selector(resetPersonality:)]];
}

- (void)presetChanged:(NSPopUpButton *)sender {
    NSString *preset = sender.selectedItem.representedObject;
    self.configuration.personalityPreset = preset;
    if (![preset isEqualToString:@"custom"]) {
        [self applyPreset:preset];
    }
}

- (void)applyPreset:(NSString *)preset {
    NSDictionary<NSString *, NSNumber *> *traits = [HALPersonality traitsForPreset:preset];
    for (NSString *key in traits) {
        [self.configuration setSettingValue:traits[key] forKey:key];
        NSSlider *slider = self.traitSliders[key];
        if (slider) [self setSliderValue:traits[key].doubleValue forSlider:slider];
    }
}

- (void)sliderChanged:(NSSlider *)sender {
    [super sliderChanged:sender];
    if ([@[@"formality", @"warmth", @"obedience", @"eeriness", @"verbosity", @"humor"] containsObject:sender.identifier]) {
        self.configuration.personalityPreset = @"custom";
        for (NSMenuItem *item in self.presetPopup.itemArray) {
            if ([item.representedObject isEqualToString:@"custom"]) {
                [self.presetPopup selectItem:item];
                break;
            }
        }
    }
}

- (void)resetPersonality:(id)sender {
    self.configuration.personalityPreset = @"classic";
    [self applyPreset:@"classic"];
    for (NSMenuItem *item in self.presetPopup.itemArray) {
        if ([item.representedObject isEqualToString:@"classic"]) {
            [self.presetPopup selectItem:item];
            break;
        }
    }
}

@end
