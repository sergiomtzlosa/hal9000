#import "HALSettingsWindowController.h"
#import "HALConfiguration.h"
#import "HALTheme.h"
#import "HALSpeechSynthesizer.h"
#import "HALSpeechRecognizer.h"
#import "HALMemoryStore.h"
#import "HALShipSimulator.h"
#import "HALSettingsPane.h"
#import "HALGeneralSettingsPane.h"
#import "HALAppearanceSettingsPane.h"
#import "HALVoiceSettingsPane.h"
#import "HALListeningSettingsPane.h"
#import "HALPersonalitySettingsPane.h"
#import "HALSimulationSettingsPane.h"
#import "HALIntelligenceSettingsPane.h"
#import "HALAdvancedSettingsPane.h"

@interface HALSettingsWindowController () <NSTableViewDataSource, NSTableViewDelegate>
@property (nonatomic, strong) HALConfiguration *configuration;
@property (nonatomic, strong) NSArray<NSDictionary *> *panes;
@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) NSView *contentContainer;
@property (nonatomic, strong) HALAdvancedSettingsPane *advancedPane;
@property (nonatomic, assign) NSInteger selectedIndex;
@end

@implementation HALSettingsWindowController

- (instancetype)initWithConfiguration:(HALConfiguration *)configuration
                  speechSynthesizer:(HALSpeechSynthesizer *)speechSynthesizer
                         recognizer:(HALSpeechRecognizer *)recognizer
                        memoryStore:(HALMemoryStore *)memoryStore
                          simulator:(HALShipSimulator *)simulator {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 860, 640)
                                                   styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable)
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    window.title = @"HAL 9000 Settings";
    window.backgroundColor = [HALTheme background];
    window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    window.minSize = NSMakeSize(780, 520);
    [window setFrameAutosaveName:@"HALSettingsWindowFrame"];
    self = [super initWithWindow:window];
    if (self) {
        _configuration = configuration;
        _selectedIndex = 0;

        HALGeneralSettingsPane *general = [[HALGeneralSettingsPane alloc] initWithConfiguration:configuration];
        HALAppearanceSettingsPane *appearance = [[HALAppearanceSettingsPane alloc] initWithConfiguration:configuration];
        HALVoiceSettingsPane *voice = [[HALVoiceSettingsPane alloc] initWithConfiguration:configuration speechSynthesizer:speechSynthesizer];
        HALListeningSettingsPane *listening = [[HALListeningSettingsPane alloc] initWithConfiguration:configuration recognizer:recognizer];
        HALPersonalitySettingsPane *personality = [[HALPersonalitySettingsPane alloc] initWithConfiguration:configuration];
        HALSimulationSettingsPane *simulation = [[HALSimulationSettingsPane alloc] initWithConfiguration:configuration];
        HALIntelligenceSettingsPane *intelligence = [[HALIntelligenceSettingsPane alloc] initWithConfiguration:configuration];
        HALAdvancedSettingsPane *advanced = [[HALAdvancedSettingsPane alloc] initWithConfiguration:configuration
                                                                                     memoryStore:memoryStore
                                                                                       simulator:simulator
                                                                             speechSynthesizer:speechSynthesizer
                                                                                    recognizer:recognizer];
        self.advancedPane = advanced;
        __weak typeof(self) weakSelf = self;
        advanced.onClearConversation = ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (self.onClearConversation) self.onClearConversation();
        };

        _panes = @[
            @{@"title": @"General", @"controller": general},
            @{@"title": @"Appearance", @"controller": appearance},
            @{@"title": @"Voice", @"controller": voice},
            @{@"title": @"Listening", @"controller": listening},
            @{@"title": @"Personality", @"controller": personality},
            @{@"title": @"Simulation", @"controller": simulation},
            @{@"title": @"Intelligence", @"controller": intelligence},
            @{@"title": @"Advanced", @"controller": advanced}
        ];
        [self buildInterface];
    }
    return self;
}

- (void)buildInterface {
    NSView *root = self.window.contentView;
    root.wantsLayer = YES;
    root.layer.backgroundColor = [HALTheme background].CGColor;

    NSView *sidebar = [[NSView alloc] initWithFrame:NSZeroRect];
    sidebar.translatesAutoresizingMaskIntoConstraints = NO;
    sidebar.wantsLayer = YES;
    sidebar.layer.backgroundColor = [HALTheme panel].CGColor;
    sidebar.layer.borderColor = [HALTheme line].CGColor;
    sidebar.layer.borderWidth = 1.0;
    [root addSubview:sidebar];

    NSTextField *title = [NSTextField labelWithString:@"SETTINGS"];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.font = [HALTheme monoFontOfSize:10 weight:NSFontWeightSemibold];
    title.textColor = [HALTheme secondaryText];
    [sidebar addSubview:title];

    self.tableView = [[NSTableView alloc] initWithFrame:NSZeroRect];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.headerView = nil;
    self.tableView.backgroundColor = [HALTheme panel];
    self.tableView.rowHeight = 34;
    self.tableView.intercellSpacing = NSMakeSize(0, 2);
    self.tableView.style = NSTableViewStyleSourceList;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"title"];
    column.width = 180;
    [self.tableView addTableColumn:column];

    NSScrollView *tableScroll = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    tableScroll.translatesAutoresizingMaskIntoConstraints = NO;
    tableScroll.drawsBackground = NO;
    tableScroll.hasVerticalScroller = NO;
    tableScroll.borderType = NSNoBorder;
    tableScroll.documentView = self.tableView;
    [sidebar addSubview:tableScroll];

    self.contentContainer = [[NSView alloc] initWithFrame:NSZeroRect];
    self.contentContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:self.contentContainer];

    [NSLayoutConstraint activateConstraints:@[
        [sidebar.topAnchor constraintEqualToAnchor:root.topAnchor],
        [sidebar.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
        [sidebar.bottomAnchor constraintEqualToAnchor:root.bottomAnchor],
        [sidebar.widthAnchor constraintEqualToConstant:190],

        [title.topAnchor constraintEqualToAnchor:sidebar.topAnchor constant:18],
        [title.leadingAnchor constraintEqualToAnchor:sidebar.leadingAnchor constant:18],

        [tableScroll.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:12],
        [tableScroll.leadingAnchor constraintEqualToAnchor:sidebar.leadingAnchor constant:8],
        [tableScroll.trailingAnchor constraintEqualToAnchor:sidebar.trailingAnchor constant:-8],
        [tableScroll.bottomAnchor constraintEqualToAnchor:sidebar.bottomAnchor constant:-12],

        [self.contentContainer.topAnchor constraintEqualToAnchor:root.topAnchor],
        [self.contentContainer.leadingAnchor constraintEqualToAnchor:sidebar.trailingAnchor],
        [self.contentContainer.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
        [self.contentContainer.bottomAnchor constraintEqualToAnchor:root.bottomAnchor]
    ]];

    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    [self showPaneAtIndex:0];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return (NSInteger)self.panes.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *cell = [tableView makeViewWithIdentifier:@"SettingsCell" owner:self];
    if (!cell) {
        cell = [[NSTableCellView alloc] initWithFrame:NSMakeRect(0, 0, 174, 32)];
        cell.identifier = @"SettingsCell";
        NSTextField *label = [NSTextField labelWithString:@""];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.font = [HALTheme uiFontOfSize:12 weight:NSFontWeightRegular];
        label.textColor = [HALTheme text];
        [cell addSubview:label];
        cell.textField = label;
        [NSLayoutConstraint activateConstraints:@[
            [label.leadingAnchor constraintEqualToAnchor:cell.leadingAnchor constant:6],
            [label.trailingAnchor constraintEqualToAnchor:cell.trailingAnchor constant:-4],
            [label.centerYAnchor constraintEqualToAnchor:cell.centerYAnchor]
        ]];
    }
    cell.textField.stringValue = self.panes[row][@"title"];
    return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = self.tableView.selectedRow;
    if (row >= 0 && row < (NSInteger)self.panes.count) {
        [self showPaneAtIndex:row];
    }
}

- (void)showPaneAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)self.panes.count) return;
    if (self.selectedIndex == index && self.contentContainer.subviews.count > 0) {
        return;
    }
    self.selectedIndex = index;
    for (NSView *view in self.contentContainer.subviews) {
        [view removeFromSuperview];
    }
    NSViewController *controller = self.panes[index][@"controller"];
    NSView *paneView = controller.view;
    paneView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentContainer addSubview:paneView];
    [NSLayoutConstraint activateConstraints:@[
        [paneView.topAnchor constraintEqualToAnchor:self.contentContainer.topAnchor],
        [paneView.leadingAnchor constraintEqualToAnchor:self.contentContainer.leadingAnchor],
        [paneView.trailingAnchor constraintEqualToAnchor:self.contentContainer.trailingAnchor],
        [paneView.bottomAnchor constraintEqualToAnchor:self.contentContainer.bottomAnchor]
    ]];
}

- (void)showSettings {
    [self showWindow:nil];
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

@end
