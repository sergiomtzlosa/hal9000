#import "HALMainWindowController.h"
#import "HALConfiguration.h"
#import "HALTheme.h"

@implementation HALMainWindowController

- (instancetype)initWithConfiguration:(HALConfiguration *)configuration
                contentViewController:(NSViewController *)contentViewController {
    NSRect frame = NSMakeRect(0, 0, 1040, 700);
    NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                              NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable |
                              NSWindowStyleMaskFullSizeContentView;
    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                   styleMask:style
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    window.title = @"HAL 9000";
    window.titleVisibility = NSWindowTitleHidden;
    window.titlebarAppearsTransparent = YES;
    window.backgroundColor = [HALTheme background];
    window.opaque = NO;
    window.movableByWindowBackground = YES;
    window.minSize = NSMakeSize(820, 560);
    window.collectionBehavior = NSWindowCollectionBehaviorFullScreenPrimary;
    window.contentViewController = contentViewController;

    self = [super initWithWindow:window];
    if (self) {
        NSString *autosaveName = @"HALMainWindowFrame";
        NSString *savedFrame = [[NSUserDefaults standardUserDefaults] stringForKey:[@"NSWindow Frame " stringByAppendingString:autosaveName]];
        if (configuration.restoreWindowFrame && savedFrame.length > 0) {
            [window setFrameAutosaveName:autosaveName];
        } else {
            // First launch (or frame restoring disabled): put the control room
            // in the middle of the active screen rather than the lower-left
            // corner of the desktop.
            [window center];
            if (configuration.restoreWindowFrame) {
                [window setFrameAutosaveName:autosaveName];
            }
        }
        [self applyConfiguration:configuration];
    }
    return self;
}

- (void)applyConfiguration:(HALConfiguration *)configuration {
    self.window.alphaValue = MAX(0.75, MIN(1.0, configuration.windowOpacity));
    self.window.level = configuration.alwaysOnTop ? NSFloatingWindowLevel : NSNormalWindowLevel;
}

@end
