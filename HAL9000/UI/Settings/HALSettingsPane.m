#import "HALSettingsPane.h"
#import "HALConfiguration.h"
#import "HALTheme.h"

@interface HALSettingsFlippedView : NSView
@end
@implementation HALSettingsFlippedView
- (BOOL)isFlipped { return YES; }
@end

@interface HALSettingsPane ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSTextField *> *valueLabels;
@property (nonatomic, strong) NSStackView *stack;
@end

@implementation HALSettingsPane

- (instancetype)initWithConfiguration:(HALConfiguration *)configuration {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _configuration = configuration;
        _valueLabels = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSStackView *)scrollableStack {
    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 560, 560)];
    scroll.drawsBackground = NO;
    scroll.hasVerticalScroller = YES;
    scroll.autohidesScrollers = YES;
    scroll.borderType = NSNoBorder;

    HALSettingsFlippedView *document = [[HALSettingsFlippedView alloc] initWithFrame:NSMakeRect(0, 0, 560, 800)];
    document.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.documentView = document;

    NSStackView *stack = [[NSStackView alloc] initWithFrame:NSZeroRect];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.orientation = NSUserInterfaceLayoutOrientationVertical;
    stack.alignment = NSLayoutAttributeLeading;
    stack.spacing = 9;
    stack.edgeInsets = NSEdgeInsetsMake(24, 26, 30, 26);
    [document addSubview:stack];
    self.stack = stack;

    [NSLayoutConstraint activateConstraints:@[
        [document.widthAnchor constraintEqualToAnchor:scroll.contentView.widthAnchor],
        [stack.topAnchor constraintEqualToAnchor:document.topAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:document.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:document.trailingAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:document.bottomAnchor]
    ]];
    self.view = scroll;
    return stack;
}

- (NSTextField *)sectionTitle:(NSString *)title {
    NSTextField *label = [NSTextField labelWithString:title.uppercaseString];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [HALTheme monoFontOfSize:10 weight:NSFontWeightSemibold];
    label.textColor = [HALTheme halRed];
    [label setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
    return label;
}

- (NSTextField *)rowLabel:(NSString *)text {
    NSTextField *label = [NSTextField labelWithString:text];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [HALTheme uiFontOfSize:12 weight:NSFontWeightRegular];
    label.textColor = [HALTheme text];
    [label.widthAnchor constraintEqualToConstant:170].active = YES;
    return label;
}

- (NSTextField *)helpText:(NSString *)text {
    NSTextField *label = [NSTextField wrappingLabelWithString:text];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [HALTheme uiFontOfSize:10 weight:NSFontWeightRegular];
    label.textColor = [HALTheme secondaryText];
    label.preferredMaxLayoutWidth = 480;
    return label;
}

- (NSStackView *)rowWithLabel:(NSString *)label control:(NSView *)control {
    return [self rowWithLabel:label control:control valueLabel:nil];
}

- (NSStackView *)rowWithLabel:(NSString *)label control:(NSView *)control valueLabel:(NSTextField *)valueLabel {
    NSTextField *labelView = [self rowLabel:label];
    NSMutableArray *views = [NSMutableArray arrayWithObjects:labelView, control, nil];
    if (valueLabel) [views addObject:valueLabel];
    NSStackView *row = [NSStackView stackViewWithViews:views];
    row.translatesAutoresizingMaskIntoConstraints = NO;
    row.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    row.alignment = NSLayoutAttributeCenterY;
    row.spacing = 10;
    [row.widthAnchor constraintEqualToConstant:520].active = YES;
    if (valueLabel) {
        [valueLabel.widthAnchor constraintEqualToConstant:64].active = YES;
    }
    return row;
}

- (NSButton *)checkboxWithTitle:(NSString *)title key:(NSString *)key {
    NSButton *button = [NSButton checkboxWithTitle:title target:self action:@selector(boolChanged:)];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.identifier = key;
    button.font = [HALTheme uiFontOfSize:12 weight:NSFontWeightRegular];
    button.contentTintColor = [HALTheme text];
    id value = [self.configuration settingValueForKey:key];
    button.state = [value boolValue] ? NSControlStateValueOn : NSControlStateValueOff;
    return button;
}

- (NSSlider *)sliderWithKey:(NSString *)key minimum:(double)minimum maximum:(double)maximum {
    NSSlider *slider = [NSSlider sliderWithValue:[[self.configuration settingValueForKey:key] doubleValue]
                                       minValue:minimum
                                       maxValue:maximum
                                         target:self
                                         action:@selector(sliderChanged:)];
    slider.translatesAutoresizingMaskIntoConstraints = NO;
    slider.identifier = key;
    slider.continuous = YES;
    [slider.widthAnchor constraintEqualToConstant:260].active = YES;
    return slider;
}

- (NSSlider *)addSliderRowWithKey:(NSString *)key label:(NSString *)label minimum:(double)minimum maximum:(double)maximum {
    NSSlider *slider = [self sliderWithKey:key minimum:minimum maximum:maximum];
    NSTextField *valueLabel = [self valueLabelForSlider:slider];
    if (self.stack) {
        [self.stack addArrangedSubview:[self rowWithLabel:label control:slider valueLabel:valueLabel]];
    }
    return slider;
}

- (NSTextField *)valueLabelForSlider:(NSSlider *)slider {
    NSTextField *label = [NSTextField labelWithString:[NSString stringWithFormat:@"%.2f", slider.doubleValue]];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = [HALTheme monoFontOfSize:10 weight:NSFontWeightRegular];
    label.textColor = [HALTheme secondaryText];
    label.alignment = NSTextAlignmentRight;
    if (slider.identifier.length) {
        self.valueLabels[slider.identifier] = label;
    }
    return label;
}

- (void)setSliderValue:(double)value forSlider:(NSSlider *)slider {
    slider.doubleValue = value;
    NSTextField *label = self.valueLabels[slider.identifier];
    if (label) {
        label.stringValue = [NSString stringWithFormat:@"%.2f", value];
    }
}

- (NSTextField *)textFieldWithKey:(NSString *)key placeholder:(NSString *)placeholder {
    NSTextField *field = [[NSTextField alloc] initWithFrame:NSZeroRect];
    field.translatesAutoresizingMaskIntoConstraints = NO;
    field.identifier = key;
    field.delegate = self;
    field.font = [HALTheme uiFontOfSize:12 weight:NSFontWeightRegular];
    field.textColor = [HALTheme text];
    field.backgroundColor = [HALTheme colorFromHex:@"#101316"];
    field.placeholderString = placeholder;
    field.bezeled = YES;
    field.bezelStyle = NSTextFieldSquareBezel;
    field.focusRingType = NSFocusRingTypeNone;
    [field.widthAnchor constraintEqualToConstant:300].active = YES;
    field.stringValue = [[self.configuration settingValueForKey:key] description] ?: @"";
    return field;
}

- (NSTextField *)multilineTextFieldWithKey:(NSString *)key height:(CGFloat)height {
    NSTextField *field = [[NSTextField alloc] initWithFrame:NSZeroRect];
    field.translatesAutoresizingMaskIntoConstraints = NO;
    field.identifier = key;
    field.delegate = self;
    field.font = [HALTheme uiFontOfSize:12 weight:NSFontWeightRegular];
    field.textColor = [HALTheme text];
    field.backgroundColor = [HALTheme colorFromHex:@"#101316"];
    field.bezeled = YES;
    field.focusRingType = NSFocusRingTypeNone;
    ((NSTextFieldCell *)field.cell).wraps = YES;
    ((NSTextFieldCell *)field.cell).scrollable = YES;
    ((NSTextFieldCell *)field.cell).usesSingleLineMode = NO;
    field.stringValue = [[self.configuration settingValueForKey:key] description] ?: @"";
    [field.heightAnchor constraintEqualToConstant:height].active = YES;
    [field.widthAnchor constraintEqualToConstant:300].active = YES;
    return field;
}

- (NSPopUpButton *)popupWithKey:(NSString *)key options:(NSArray<NSDictionary<NSString *, NSString *> *> *)options {
    NSPopUpButton *popup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    popup.translatesAutoresizingMaskIntoConstraints = NO;
    popup.identifier = key;
    popup.target = self;
    popup.action = @selector(popupChanged:);
    popup.font = [HALTheme uiFontOfSize:12 weight:NSFontWeightRegular];
    NSString *current = [self.configuration settingValueForKey:key];
    for (NSDictionary *option in options) {
        [popup addItemWithTitle:option[@"title"]];
        popup.lastItem.representedObject = option[@"value"];
        if ([option[@"value"] isEqualToString:current]) {
            [popup selectItem:popup.lastItem];
        }
    }
    [popup.widthAnchor constraintEqualToConstant:260].active = YES;
    return popup;
}

- (NSColorWell *)colorWellWithKey:(NSString *)key {
    NSColorWell *well = [[NSColorWell alloc] initWithFrame:NSZeroRect];
    well.translatesAutoresizingMaskIntoConstraints = NO;
    well.identifier = key;
    well.target = self;
    well.action = @selector(colorChanged:);
    well.color = [HALTheme colorFromHex:[self.configuration settingValueForKey:key]];
    [well.widthAnchor constraintEqualToConstant:56].active = YES;
    [well.heightAnchor constraintEqualToConstant:28].active = YES;
    return well;
}

- (NSButton *)buttonWithTitle:(NSString *)title action:(SEL)action {
    NSButton *button = [NSButton buttonWithTitle:title target:self action:action];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.font = [HALTheme uiFontOfSize:11 weight:NSFontWeightMedium];
    button.bezelStyle = NSBezelStyleRounded;
    [button.heightAnchor constraintEqualToConstant:28].active = YES;
    return button;
}

- (void)boolChanged:(NSButton *)sender {
    if (sender.identifier.length == 0) return;
    [self.configuration setSettingValue:@(sender.state == NSControlStateValueOn) forKey:sender.identifier];
}

- (void)sliderChanged:(NSSlider *)sender {
    if (sender.identifier.length == 0) return;
    [self.configuration setSettingValue:@(sender.doubleValue) forKey:sender.identifier];
    NSTextField *valueLabel = self.valueLabels[sender.identifier];
    if (valueLabel) {
        valueLabel.stringValue = [NSString stringWithFormat:@"%.2f", sender.doubleValue];
    }
}

- (void)textChanged:(NSTextField *)sender {
    if (sender.identifier.length == 0) return;
    [self.configuration setSettingValue:(sender.stringValue ?: @"") forKey:sender.identifier];
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    NSTextField *field = obj.object;
    if ([field isKindOfClass:[NSTextField class]]) {
        [self textChanged:field];
    }
}

- (void)popupChanged:(NSPopUpButton *)sender {
    if (sender.identifier.length == 0) return;
    id value = sender.selectedItem.representedObject ?: sender.titleOfSelectedItem;
    [self.configuration setSettingValue:value forKey:sender.identifier];
}

- (void)colorChanged:(NSColorWell *)sender {
    if (sender.identifier.length == 0) return;
    [self.configuration setSettingValue:[HALTheme hexFromColor:sender.color] forKey:sender.identifier];
}

@end
