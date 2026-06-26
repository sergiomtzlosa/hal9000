#import "HALGeneralSettingsPane.h"
#import "HALTheme.h"

@implementation HALGeneralSettingsPane

- (void)loadView {
    NSStackView *stack = [self scrollableStack];

    [stack addArrangedSubview:[self sectionTitle:@"General"]];
    [stack addArrangedSubview:[self helpText:@"How HAL addresses you and behaves at launch. Changes apply immediately."]];

    NSTextField *nameField = [self textFieldWithKey:@"userName" placeholder:@"Your name"];
    [stack addArrangedSubview:[self rowWithLabel:@"Your name" control:nameField]];

    NSPopUpButton *startMode = [self popupWithKey:@"startMode" options:@[
        @{@"title": @"Standard control room", @"value": @"standard"},
        @{@"title": @"Cinema mode", @"value": @"cinema"},
        @{@"title": @"Compact eye", @"value": @"compact"}
    ]];
    [stack addArrangedSubview:[self rowWithLabel:@"Start in" control:startMode]];

    [stack addArrangedSubview:[self checkboxWithTitle:@"Play the boot sequence" key:@"bootSequence"]];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Restore the previous conversation" key:@"restoreConversation"]];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Save transcripts to Application Support" key:@"saveTranscripts"]];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Show the menu bar icon" key:@"showMenuBarIcon"]];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Confirm before quitting from a HAL command" key:@"confirmQuit"]];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Restore the main window frame" key:@"restoreWindowFrame"]];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Launch at login" key:@"launchAtLogin"]];
    [stack addArrangedSubview:[self helpText:@"Launch at login requires a signed app in /Applications on some systems. If registration fails, the setting remains off and an alert explains why."]];
}

@end
