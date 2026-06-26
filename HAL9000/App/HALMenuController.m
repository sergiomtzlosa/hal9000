#import "HALMenuController.h"
#import "HALAppController.h"

@interface HALMenuController ()
@property (nonatomic, strong, nullable) NSMenuItem *listenItem;
@property (nonatomic, strong, nullable) NSMenuItem *muteItem;
@end

@implementation HALMenuController

- (void)installMainMenuWithTarget:(id)target {
    NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@"Main Menu"];

    NSMenuItem *appItem = [[NSMenuItem alloc] initWithTitle:@"HAL 9000" action:nil keyEquivalent:@""];
    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"HAL 9000"];
    [appMenu addItem:[self itemWithTitle:@"About HAL 9000" action:@selector(showAbout:) target:target key:@"" modifiers:0]];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItem:[self itemWithTitle:@"Settings…" action:@selector(openSettings:) target:target key:@"," modifiers:NSEventModifierFlagCommand]];
    [appMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *servicesItem = [[NSMenuItem alloc] initWithTitle:@"Services" action:nil keyEquivalent:@""];
    NSMenu *servicesMenu = [[NSMenu alloc] initWithTitle:@"Services"];
    servicesItem.submenu = servicesMenu;
    [appMenu addItem:servicesItem];
    [NSApp setServicesMenu:servicesMenu];
    [appMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *hide = [[NSMenuItem alloc] initWithTitle:@"Hide HAL 9000" action:@selector(hide:) keyEquivalent:@"h"];
    hide.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    [appMenu addItem:hide];
    NSMenuItem *hideOthers = [[NSMenuItem alloc] initWithTitle:@"Hide Others" action:@selector(hideOtherApplications:) keyEquivalent:@"h"];
    hideOthers.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagOption;
    [appMenu addItem:hideOthers];
    NSMenuItem *showAll = [[NSMenuItem alloc] initWithTitle:@"Show All" action:@selector(unhideAllApplications:) keyEquivalent:@""];
    [appMenu addItem:showAll];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItem:[self itemWithTitle:@"Quit HAL 9000" action:@selector(terminateFromMenu:) target:target key:@"q" modifiers:NSEventModifierFlagCommand]];
    appItem.submenu = appMenu;
    [mainMenu addItem:appItem];

    NSMenuItem *editItem = [[NSMenuItem alloc] initWithTitle:@"Edit" action:nil keyEquivalent:@""];
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
    [editMenu addItem:[self standardItem:@"Undo" action:NSSelectorFromString(@"undo:") key:@"z"]];
    [editMenu addItem:[self standardItem:@"Redo" action:NSSelectorFromString(@"redo:") key:@"Z"]];
    [editMenu addItem:[NSMenuItem separatorItem]];
    [editMenu addItem:[self standardItem:@"Cut" action:@selector(cut:) key:@"x"]];
    [editMenu addItem:[self standardItem:@"Copy" action:@selector(copy:) key:@"c"]];
    [editMenu addItem:[self standardItem:@"Paste" action:@selector(paste:) key:@"v"]];
    [editMenu addItem:[self standardItem:@"Delete" action:@selector(delete:) key:@""]];
    [editMenu addItem:[self standardItem:@"Select All" action:@selector(selectAll:) key:@"a"]];
    editItem.submenu = editMenu;
    [mainMenu addItem:editItem];

    NSMenuItem *viewItem = [[NSMenuItem alloc] initWithTitle:@"View" action:nil keyEquivalent:@""];
    NSMenu *viewMenu = [[NSMenu alloc] initWithTitle:@"View"];
    [viewMenu addItem:[self itemWithTitle:@"Cinema Mode" action:@selector(enterCinema:) target:target key:@"f" modifiers:(NSEventModifierFlagCommand | NSEventModifierFlagShift)]];
    [viewMenu addItem:[self itemWithTitle:@"Compact Mode" action:@selector(enterCompact:) target:target key:@"c" modifiers:(NSEventModifierFlagCommand | NSEventModifierFlagShift)]];
    [viewMenu addItem:[self itemWithTitle:@"Toggle Sidebar" action:@selector(toggleSidebar:) target:target key:@"s" modifiers:(NSEventModifierFlagCommand | NSEventModifierFlagShift)]];
    [viewMenu addItem:[NSMenuItem separatorItem]];
    [viewMenu addItem:[self itemWithTitle:@"3D Viewer…" action:@selector(open3DViewer:) target:target key:@"3" modifiers:NSEventModifierFlagCommand]];
    [viewMenu addItem:[NSMenuItem separatorItem]];
    [viewMenu addItem:[self standardItem:@"Enter Full Screen" action:@selector(toggleFullScreen:) key:@"f"]];
    viewItem.submenu = viewMenu;
    [mainMenu addItem:viewItem];

    NSMenuItem *conversationItem = [[NSMenuItem alloc] initWithTitle:@"Conversation" action:nil keyEquivalent:@""];
    NSMenu *conversationMenu = [[NSMenu alloc] initWithTitle:@"Conversation"];
    self.listenItem = [self itemWithTitle:@"Listen" action:@selector(toggleListening:) target:target key:@"l" modifiers:(NSEventModifierFlagCommand | NSEventModifierFlagShift)];
    [conversationMenu addItem:self.listenItem];
    [conversationMenu addItem:[self itemWithTitle:@"Stop Speaking" action:@selector(stopSpeaking:) target:target key:@"." modifiers:NSEventModifierFlagCommand]];
    self.muteItem = [self itemWithTitle:@"Mute" action:@selector(toggleMute:) target:target key:@"m" modifiers:(NSEventModifierFlagCommand | NSEventModifierFlagShift)];
    [conversationMenu addItem:self.muteItem];
    [conversationMenu addItem:[NSMenuItem separatorItem]];
    [conversationMenu addItem:[self itemWithTitle:@"Run Diagnostics" action:@selector(runDiagnostics:) target:target key:@"d" modifiers:(NSEventModifierFlagCommand | NSEventModifierFlagShift)]];
    [conversationMenu addItem:[self itemWithTitle:@"Clear Conversation" action:@selector(clearConversation:) target:target key:@"k" modifiers:NSEventModifierFlagCommand]];
    [conversationMenu addItem:[self itemWithTitle:@"Export Transcript…" action:@selector(exportTranscript:) target:target key:@"" modifiers:0]];
    conversationItem.submenu = conversationMenu;
    [mainMenu addItem:conversationItem];

    NSMenuItem *windowItem = [[NSMenuItem alloc] initWithTitle:@"Window" action:nil keyEquivalent:@""];
    NSMenu *windowMenu = [[NSMenu alloc] initWithTitle:@"Window"];
    [windowMenu addItem:[self standardItem:@"Minimize" action:@selector(performMiniaturize:) key:@"m"]];
    [windowMenu addItem:[self standardItem:@"Zoom" action:@selector(performZoom:) key:@""]];
    [windowMenu addItem:[self standardItem:@"Close" action:@selector(performClose:) key:@"w"]];
    [windowMenu addItem:[NSMenuItem separatorItem]];
    [windowMenu addItem:[self itemWithTitle:@"Bring All to Front" action:@selector(arrangeInFront:) target:NSApp key:@"" modifiers:0]];
    windowItem.submenu = windowMenu;
    [mainMenu addItem:windowItem];
    [NSApp setWindowsMenu:windowMenu];

    NSMenuItem *helpItem = [[NSMenuItem alloc] initWithTitle:@"Help" action:nil keyEquivalent:@""];
    NSMenu *helpMenu = [[NSMenu alloc] initWithTitle:@"Help"];
    [helpMenu addItem:[self itemWithTitle:@"HAL 9000 Help" action:@selector(openHelp:) target:target key:@"?" modifiers:NSEventModifierFlagCommand]];
    [helpMenu addItem:[NSMenuItem separatorItem]];
    [helpMenu addItem:[self itemWithTitle:@"HAL 9000 Fan Project" action:@selector(showAbout:) target:target key:@"" modifiers:0]];
    helpItem.submenu = helpMenu;
    [mainMenu addItem:helpItem];

    [NSApp setMainMenu:mainMenu];
}

- (NSMenuItem *)itemWithTitle:(NSString *)title action:(SEL)action target:(id)target key:(NSString *)key modifiers:(NSEventModifierFlags)modifiers {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:key];
    item.target = target;
    item.keyEquivalentModifierMask = modifiers;
    return item;
}

- (NSMenuItem *)standardItem:(NSString *)title action:(SEL)action key:(NSString *)key {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:key];
    if (key.length) item.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    return item;
}

- (void)updateListening:(BOOL)listening muted:(BOOL)muted {
    self.listenItem.title = listening ? @"Stop Listening" : @"Listen";
    self.muteItem.state = muted ? NSControlStateValueOn : NSControlStateValueOff;
}

@end
