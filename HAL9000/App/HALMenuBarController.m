#import "HALMenuBarController.h"
#import "HALTheme.h"

@interface HALMenuBarController ()
@property (nonatomic, strong, nullable) NSStatusItem *statusItem;
@property (nonatomic, strong, nullable) NSMenu *menu;
@property (nonatomic, strong, nullable) NSMenuItem *listenItem;
@property (nonatomic, strong, nullable) NSMenuItem *muteItem;
@end

@implementation HALMenuBarController

- (void)setVisible:(BOOL)visible {
    if (visible && !self.statusItem) {
        [self createStatusItem];
    } else if (!visible && self.statusItem) {
        [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
        self.statusItem = nil;
        self.menu = nil;
    }
}

- (void)createStatusItem {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.image = [self iconImage];
    self.statusItem.button.toolTip = @"HAL 9000";
    self.statusItem.button.accessibilityLabel = @"HAL 9000";

    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"HAL 9000"];
    menu.autoenablesItems = NO;

    NSMenuItem *show = [[NSMenuItem alloc] initWithTitle:@"Show HAL" action:@selector(showPressed:) keyEquivalent:@""];
    show.target = self;
    [menu addItem:show];

    self.listenItem = [[NSMenuItem alloc] initWithTitle:@"Listen" action:@selector(listenPressed:) keyEquivalent:@""];
    self.listenItem.target = self;
    [menu addItem:self.listenItem];

    NSMenuItem *stop = [[NSMenuItem alloc] initWithTitle:@"Stop Speaking" action:@selector(stopPressed:) keyEquivalent:@""];
    stop.target = self;
    [menu addItem:stop];
    [menu addItem:[NSMenuItem separatorItem]];

    self.muteItem = [[NSMenuItem alloc] initWithTitle:@"Mute" action:@selector(mutePressed:) keyEquivalent:@""];
    self.muteItem.target = self;
    [menu addItem:self.muteItem];

    NSMenuItem *settings = [[NSMenuItem alloc] initWithTitle:@"Settings…" action:@selector(settingsPressed:) keyEquivalent:@","];
    settings.target = self;
    settings.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    [menu addItem:settings];

    NSMenuItem *threeD = [[NSMenuItem alloc] initWithTitle:@"3D Viewer…" action:@selector(threeDPressed:) keyEquivalent:@"3"];
    threeD.target = self;
    threeD.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    [menu addItem:threeD];

    NSMenuItem *help = [[NSMenuItem alloc] initWithTitle:@"HAL 9000 Help" action:@selector(helpPressed:) keyEquivalent:@"?"];
    help.target = self;
    help.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    [menu addItem:help];
    [menu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *about = [[NSMenuItem alloc] initWithTitle:@"About HAL 9000" action:@selector(aboutPressed:) keyEquivalent:@""];
    about.target = self;
    [menu addItem:about];

    NSMenuItem *quit = [[NSMenuItem alloc] initWithTitle:@"Quit HAL 9000" action:@selector(quitPressed:) keyEquivalent:@"q"];
    quit.target = self;
    quit.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    [menu addItem:quit];

    self.menu = menu;
    self.statusItem.menu = menu;
}

- (void)updateListening:(BOOL)listening muted:(BOOL)muted {
    self.listenItem.title = listening ? @"Stop Listening" : @"Listen";
    self.muteItem.state = muted ? NSControlStateValueOn : NSControlStateValueOff;
    self.statusItem.button.appearsDisabled = muted;
    self.statusItem.button.toolTip = muted ? @"HAL 9000 — muted" : (listening ? @"HAL 9000 — listening" : @"HAL 9000");
}

- (NSImage *)iconImage {
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(18, 18)];
    [image lockFocus];
    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0, 0, 18, 18));

    NSRect outer = NSMakeRect(2.0, 2.0, 14.0, 14.0);
    NSBezierPath *ring = [NSBezierPath bezierPathWithOvalInRect:outer];
    [[NSColor colorWithWhite:0.55 alpha:0.95] setStroke];
    ring.lineWidth = 1.4;
    [ring stroke];

    NSBezierPath *inner = [NSBezierPath bezierPathWithOvalInRect:NSInsetRect(outer, 2.6, 2.6)];
    [[HALTheme halRed] setFill];
    [inner fill];

    NSBezierPath *pupil = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(7.3, 7.3, 3.4, 3.4)];
    [[NSColor colorWithWhite:0.96 alpha:1.0] setFill];
    [pupil fill];
    [image unlockFocus];
    image.template = NO;
    return image;
}

- (void)showPressed:(id)sender { if (self.onShowHAL) self.onShowHAL(); }
- (void)listenPressed:(id)sender { if (self.onListen) self.onListen(); }
- (void)stopPressed:(id)sender { if (self.onStopSpeaking) self.onStopSpeaking(); }
- (void)mutePressed:(id)sender { if (self.onMute) self.onMute(); }
- (void)settingsPressed:(id)sender { if (self.onSettings) self.onSettings(); }
- (void)threeDPressed:(id)sender { if (self.onOpen3D) self.onOpen3D(); }
- (void)helpPressed:(id)sender { if (self.onHelp) self.onHelp(); }
- (void)aboutPressed:(id)sender { if (self.onAbout) self.onAbout(); }
- (void)quitPressed:(id)sender { if (self.onQuit) self.onQuit(); }

@end
