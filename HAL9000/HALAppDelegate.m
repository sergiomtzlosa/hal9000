#import "HALAppDelegate.h"
#import "HALAppController.h"
#import "HALConfiguration.h"

@interface HALAppDelegate ()
@property (nonatomic, strong) HALAppController *appController;
@end

@implementation HALAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // HAL is a deliberately dark control-room interface. Forcing the dark
    // appearance also keeps system controls (pop-up buttons, text fields,
    // source-list rows) legible against the custom dark panels.
    NSApp.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];

    NSArray<NSString *> *arguments = [NSProcessInfo processInfo].arguments;
    BOOL safeMode = [arguments containsObject:@"--safe-mode"];
    BOOL skipBoot = [arguments containsObject:@"--skip-boot"];
    BOOL resetDefaults = [arguments containsObject:@"--reset-defaults"];

    if (resetDefaults) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Reset all HAL 9000 settings?";
        alert.informativeText = @"The --reset-defaults launch argument restores every option to its default. Transcripts and the Keychain API key are preserved.";
        [alert addButtonWithTitle:@"Reset"];
        [alert addButtonWithTitle:@"Cancel"];
        alert.alertStyle = NSAlertStyleWarning;
        if ([alert runModal] == NSAlertFirstButtonReturn) {
            [[HALConfiguration sharedConfiguration] resetToDefaults];
        }
    }

    self.appController = [[HALAppController alloc] initWithSafeMode:safeMode skipBoot:skipBoot];
    [self.appController start];
    [NSApp activateIgnoringOtherApps:YES];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return NO;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    [self.appController showMainWindow:nil];
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [self.appController shutdown];
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

@end
