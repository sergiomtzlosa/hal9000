#import "HALStatusSidebarViewController.h"
#import "HALTheme.h"

@interface HALStatusSidebarViewController ()
@property (nonatomic, strong) NSTextField *missionLabel;
@property (nonatomic, strong) NSTextField *statusLabel;
@property (nonatomic, strong) NSTextField *eventsLabel;
@property (nonatomic, strong) NSPopUpButton *scenarioPopup;
@end

@implementation HALStatusSidebarViewController

- (void)loadView {
    NSView *root = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 260, 600)];
    root.wantsLayer = YES;
    root.layer.backgroundColor = [HALTheme panel].CGColor;
    self.view = root;

    NSStackView *stack = [[NSStackView alloc] initWithFrame:NSZeroRect];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.orientation = NSUserInterfaceLayoutOrientationVertical;
    stack.alignment = NSLayoutAttributeLeading;
    stack.spacing = 10;
    stack.edgeInsets = NSEdgeInsetsMake(18, 18, 18, 18);
    [root addSubview:stack];

    NSTextField *title = [self labelWithString:@"SHIP SYSTEMS" font:[HALTheme monoFontOfSize:10 weight:NSFontWeightSemibold] color:[HALTheme secondaryText]];
    [stack addArrangedSubview:title];

    self.missionLabel = [self labelWithString:@"T+00:00:00" font:[HALTheme monoFontOfSize:11 weight:NSFontWeightMedium] color:[HALTheme halRed]];
    [stack addArrangedSubview:self.missionLabel];

    self.statusLabel = [self labelWithString:@"" font:[HALTheme monoFontOfSize:11 weight:NSFontWeightRegular] color:[HALTheme text]];
    self.statusLabel.maximumNumberOfLines = 0;
    self.statusLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.statusLabel.preferredMaxLayoutWidth = 220;
    [stack addArrangedSubview:self.statusLabel];

    [stack addArrangedSubview:[self separator]];

    NSTextField *scenarioTitle = [self labelWithString:@"SCENARIO" font:[HALTheme monoFontOfSize:10 weight:NSFontWeightSemibold] color:[HALTheme secondaryText]];
    [stack addArrangedSubview:scenarioTitle];

    self.scenarioPopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    self.scenarioPopup.translatesAutoresizingMaskIntoConstraints = NO;
    self.scenarioPopup.target = self;
    self.scenarioPopup.action = @selector(scenarioChanged:);
    self.scenarioPopup.font = [HALTheme uiFontOfSize:12 weight:NSFontWeightRegular];
    for (HALScenario *scenario in [HALScenario allScenarios]) {
        [self.scenarioPopup addItemWithTitle:scenario.name];
        self.scenarioPopup.lastItem.representedObject = scenario.identifier;
    }
    [self.scenarioPopup.widthAnchor constraintEqualToConstant:224].active = YES;
    [stack addArrangedSubview:self.scenarioPopup];

    NSButton *diagnostics = [self sidebarButtonWithTitle:@"RUN DIAGNOSTICS" action:@selector(diagnosticsPressed:)];
    [stack addArrangedSubview:diagnostics];

    NSButton *threeD = [self sidebarButtonWithTitle:@"OPEN 3D RECORDS" action:@selector(open3DPressed:)];
    [stack addArrangedSubview:threeD];

    [stack addArrangedSubview:[self separator]];

    NSTextField *eventsTitle = [self labelWithString:@"RECENT EVENTS" font:[HALTheme monoFontOfSize:10 weight:NSFontWeightSemibold] color:[HALTheme secondaryText]];
    [stack addArrangedSubview:eventsTitle];

    self.eventsLabel = [self labelWithString:@"No significant events." font:[HALTheme monoFontOfSize:10 weight:NSFontWeightRegular] color:[HALTheme secondaryText]];
    self.eventsLabel.maximumNumberOfLines = 0;
    self.eventsLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.eventsLabel.preferredMaxLayoutWidth = 220;
    [stack addArrangedSubview:self.eventsLabel];

    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:root.topAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
        [stack.bottomAnchor constraintLessThanOrEqualToAnchor:root.bottomAnchor constant:-12]
    ]];

    [self refresh];
}

- (NSTextField *)labelWithString:(NSString *)string font:(NSFont *)font color:(NSColor *)color {
    NSTextField *label = [NSTextField labelWithString:string];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = font;
    label.textColor = color;
    label.selectable = YES;
    label.maximumNumberOfLines = 1;
    return label;
}

- (NSView *)separator {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 224, 1)];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.wantsLayer = YES;
    view.layer.backgroundColor = [HALTheme line].CGColor;
    [view.heightAnchor constraintEqualToConstant:1].active = YES;
    [view.widthAnchor constraintEqualToConstant:224].active = YES;
    return view;
}

- (NSButton *)sidebarButtonWithTitle:(NSString *)title action:(SEL)action {
    NSButton *button = [[NSButton alloc] initWithFrame:NSZeroRect];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.bordered = NO;
    button.target = self;
    button.action = action;
    button.wantsLayer = YES;
    button.layer.cornerRadius = 5.0;
    button.layer.backgroundColor = [[HALTheme halRed] colorWithAlphaComponent:0.08].CGColor;
    button.layer.borderColor = [[HALTheme halRed] colorWithAlphaComponent:0.25].CGColor;
    button.layer.borderWidth = 1.0;
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment = NSTextAlignmentCenter;
    button.attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:@{
        NSFontAttributeName: [HALTheme monoFontOfSize:9 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: [HALTheme halRed],
        NSParagraphStyleAttributeName: paragraph
    }];
    [button.heightAnchor constraintEqualToConstant:30].active = YES;
    [button.widthAnchor constraintEqualToConstant:224].active = YES;
    return button;
}

- (void)scenarioChanged:(NSPopUpButton *)sender {
    NSString *identifier = sender.selectedItem.representedObject;
    if (identifier && self.onScenarioChanged) {
        self.onScenarioChanged(identifier);
    }
}

- (void)diagnosticsPressed:(id)sender {
    if (self.onDiagnostics) self.onDiagnostics();
}

- (void)open3DPressed:(id)sender {
    if (self.onOpen3D) self.onOpen3D();
}

- (void)refresh {
    if (!self.simulator) return;
    self.missionLabel.stringValue = [self.simulator missionTimeString];

    NSMutableAttributedString *systems = [[NSMutableAttributedString alloc] init];
    for (HALShipSystem *system in self.simulator.systems) {
        NSColor *dotColor = [HALTheme success];
        if (system.status == HALShipSystemStatusWarning) dotColor = [HALTheme warning];
        else if (system.status == HALShipSystemStatusCritical) dotColor = [HALTheme halRed];
        else if (system.status == HALShipSystemStatusOffline) dotColor = [HALTheme secondaryText];

        [systems appendAttributedString:[[NSAttributedString alloc] initWithString:@"● " attributes:@{
            NSFontAttributeName: [HALTheme monoFontOfSize:10 weight:NSFontWeightRegular],
            NSForegroundColorAttributeName: dotColor
        }]];
        [systems appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", system.name] attributes:@{
            NSFontAttributeName: [HALTheme monoFontOfSize:10 weight:NSFontWeightMedium],
            NSForegroundColorAttributeName: [HALTheme text]
        }]];
        [systems appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"   %@\n\n", [system displayValue]] attributes:@{
            NSFontAttributeName: [HALTheme monoFontOfSize:9 weight:NSFontWeightRegular],
            NSForegroundColorAttributeName: [HALTheme secondaryText]
        }]];
    }
    self.statusLabel.attributedStringValue = systems;

    NSString *scenario = self.simulator.scenario.identifier;
    for (NSMenuItem *item in self.scenarioPopup.itemArray) {
        if ([item.representedObject isEqualToString:scenario]) {
            [self.scenarioPopup selectItem:item];
            break;
        }
    }
    self.eventsLabel.stringValue = [self.simulator recentEventsSummary];
}

@end
