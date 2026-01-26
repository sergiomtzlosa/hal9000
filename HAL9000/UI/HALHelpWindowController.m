#import "HALHelpWindowController.h"
#import "HALTheme.h"

@implementation HALHelpWindowController

- (instancetype)init {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 820, 680)
                                                   styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable)
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    window.title = @"HAL 9000 Help";
    window.backgroundColor = [HALTheme background];
    window.minSize = NSMakeSize(680, 520);
    window.releasedWhenClosed = NO;
    self = [super initWithWindow:window];
    if (self) {
        [self buildInterface];
    }
    return self;
}

- (void)buildInterface {
    NSView *root = self.window.contentView;
    root.wantsLayer = YES;
    root.layer.backgroundColor = [HALTheme background].CGColor;

    NSView *header = [[NSView alloc] initWithFrame:NSZeroRect];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    header.wantsLayer = YES;
    header.layer.backgroundColor = [HALTheme panel].CGColor;
    header.layer.borderColor = [HALTheme line].CGColor;
    header.layer.borderWidth = 1.0;
    [root addSubview:header];

    NSTextField *title = [NSTextField labelWithString:@"HAL 9000 · OPERATIONS MANUAL"];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.font = [HALTheme monoFontOfSize:12 weight:NSFontWeightSemibold];
    title.textColor = [HALTheme halRed];
    [header addSubview:title];

    NSTextField *subtitle = [NSTextField labelWithString:@"A quick guide to the control room, voice input, 3D records, and privacy."];
    subtitle.translatesAutoresizingMaskIntoConstraints = NO;
    subtitle.font = [HALTheme uiFontOfSize:11 weight:NSFontWeightRegular];
    subtitle.textColor = [HALTheme secondaryText];
    [header addSubview:subtitle];

    NSButton *close = [NSButton buttonWithTitle:@"CLOSE" target:self action:@selector(closePressed:)];
    close.translatesAutoresizingMaskIntoConstraints = NO;
    close.bezelStyle = NSBezelStyleRounded;
    close.font = [HALTheme monoFontOfSize:9 weight:NSFontWeightSemibold];
    [header addSubview:close];

    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.drawsBackground = NO;
    scroll.hasVerticalScroller = YES;
    scroll.autohidesScrollers = YES;
    scroll.borderType = NSNoBorder;
    [root addSubview:scroll];

    NSTextView *textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 760, 1200)];
    textView.autoresizingMask = NSViewWidthSizable;
    textView.editable = NO;
    textView.selectable = YES;
    textView.richText = YES;
    textView.drawsBackground = NO;
    textView.textColor = [HALTheme text];
    textView.font = [HALTheme uiFontOfSize:12 weight:NSFontWeightRegular];
    textView.textContainerInset = NSMakeSize(30, 24);
    textView.textContainer.widthTracksTextView = YES;
    textView.verticallyResizable = YES;
    textView.horizontallyResizable = NO;
    textView.minSize = NSMakeSize(0, 0);
    textView.maxSize = NSMakeSize(FLT_MAX, FLT_MAX);
    textView.string = @"";
    scroll.documentView = textView;

    NSView *footer = [[NSView alloc] initWithFrame:NSZeroRect];
    footer.translatesAutoresizingMaskIntoConstraints = NO;
    footer.wantsLayer = YES;
    footer.layer.backgroundColor = [HALTheme panel].CGColor;
    footer.layer.borderColor = [HALTheme line].CGColor;
    footer.layer.borderWidth = 1.0;
    [root addSubview:footer];

    NSTextField *tip = [NSTextField labelWithString:@"TIP · Press ⌘? from anywhere to reopen this guide. HAL is fully usable offline."];
    tip.translatesAutoresizingMaskIntoConstraints = NO;
    tip.font = [HALTheme monoFontOfSize:9 weight:NSFontWeightRegular];
    tip.textColor = [HALTheme secondaryText];
    [footer addSubview:tip];

    [NSLayoutConstraint activateConstraints:@[
        [header.topAnchor constraintEqualToAnchor:root.topAnchor],
        [header.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
        [header.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
        [header.heightAnchor constraintEqualToConstant:86],

        [title.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:30],
        [title.topAnchor constraintEqualToAnchor:header.topAnchor constant:22],
        [subtitle.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:8],
        [subtitle.trailingAnchor constraintLessThanOrEqualToAnchor:close.leadingAnchor constant:-16],

        [close.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-24],
        [close.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [close.widthAnchor constraintEqualToConstant:76],
        [close.heightAnchor constraintEqualToConstant:28],

        [scroll.topAnchor constraintEqualToAnchor:header.bottomAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:footer.topAnchor],

        [footer.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
        [footer.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
        [footer.bottomAnchor constraintEqualToAnchor:root.bottomAnchor],
        [footer.heightAnchor constraintEqualToConstant:34],

        [tip.leadingAnchor constraintEqualToAnchor:footer.leadingAnchor constant:30],
        [tip.centerYAnchor constraintEqualToAnchor:footer.centerYAnchor]
    ]];

    [self populateTextView:textView];
    [textView scrollRangeToVisible:NSMakeRange(0, 0)];
}

- (void)populateTextView:(NSTextView *)textView {
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
    [self appendIntro:@"HAL 9000 is an offline-first control-room simulation. You can type, use the microphone, run ship diagnostics, switch presentation modes, and explore two original 3D scenes. Nothing here controls real hardware." to:text];
    [self appendHeading:@"Quick start" to:text];
    [self appendBullet:@"Type a message in the control-room input and press Return." to:text];
    [self appendBullet:@"Click the red eye, press ⌥Space, or click LISTEN to speak. Release or press again to finish." to:text];
    [self appendBullet:@"HAL replies in the transcript and speaks through the selected system voice." to:text];
    [self appendBullet:@"Open SETTINGS for appearance, voice, listening, personality, simulation, intelligence, and data controls." to:text];

    [self appendHeading:@"Talking to HAL" to:text];
    [self appendBody:@"Text input always works, even when the microphone is unavailable. Voice input can be push-to-talk or wake-phrase driven. The first time you listen, macOS asks for microphone and speech-recognition permission; audio is processed only while listening and is never saved by HAL 9000." to:text];
    [self appendBody:@"HAL recognizes short app commands as well as conversation. Try these:" to:text];
    [self appendBullet:@"“Mute”, “unmute”, or “stop speaking”." to:text];
    [self appendBullet:@"“Listen” or “open settings”." to:text];
    [self appendBullet:@"“Status report” or “run diagnostics”." to:text];
    [self appendBullet:@"“Cinema mode”, “compact mode”, or “open the 3D viewer”." to:text];
    [self appendBullet:@"“Clear the conversation” or “open the pod bay doors” (the latter is refused unless the simulation override is enabled)." to:text];
    [self appendBullet:@"“Quit” asks for confirmation before the app closes." to:text];

    [self appendHeading:@"The eye" to:text];
    [self appendBody:@"The eye is a state indicator, not just decoration:" to:text];
    [self appendBullet:@"Idle — slow breathing glow." to:text];
    [self appendBullet:@"Listening — a warm outer ring and a slightly open aperture." to:text];
    [self appendBullet:@"Thinking — the aperture rotates while HAL prepares a reply." to:text];
    [self appendBullet:@"Speaking — a brighter pulse while the voice synthesizer runs." to:text];
    [self appendBullet:@"Alert — a deeper red strobe for scenario warnings." to:text];
    [self appendBullet:@"Muted — dim red with a diagonal slash." to:text];
    [self appendBody:@"Reduce Motion is respected. The eye pauses automatically when its window is hidden, minimized, or covered." to:text];

    [self appendHeading:@"Control room" to:text];
    [self appendBody:@"The left column holds the eye, transcript, and input. The right sidebar shows simulated ship systems, the mission clock, recent events, scenario selection, diagnostics, and a shortcut to 3D records. Use STATUS to show or hide it. Choose a scenario to reset the simulation to a different baseline: Nominal, Jupiter Approach, AE-35 Failure, Pod Bay Lockdown, or Red Alert." to:text];
    [self appendBody:@"If the sidebar is disabled in Settings → Appearance, the transcript expands into the space." to:text];

    [self appendHeading:@"3D records" to:text];
    [self appendBody:@"Open the viewer with the 3D button or View → 3D Viewer (⌘3). In the HAL 9000 scene, drag to orbit, scroll to zoom, and Option-drag to pan. Camera presets frame the eye detail, a three-quarter view, and a wide shot." to:text];
    [self appendBody:@"The second scene is the Deactivation Room. Its camera is fixed and cannot be orbited or panned, so the room never spins; scroll or pinch to zoom, and use the camera presets or RESET VIEW to reframe it. Auto-rotate applies only to the HAL eye model. DEACTIVATE runs a purely visual sequence that dims the room and memory modules. Leaving the room or closing the viewer brings every node and light back automatically. The sequence never touches real data or hardware." to:text];

    [self appendHeading:@"Settings at a glance" to:text];
    [self appendBullet:@"General — your name, boot sequence, transcript restore, menu-bar icon, launch at login, start mode, window frame." to:text];
    [self appendBullet:@"Appearance — eye color and scale, glow, pulse, blink, cursor tracking, scanlines, grain, window opacity, sidebar, subtitles, text scale, 3D quality." to:text];
    [self appendBullet:@"Voice — system voice, character preset, rate, pitch, volume, preview, auto-speak." to:text];
    [self appendBullet:@"Listening — enable, push-to-talk or wake phrase, locale, silence timeout, on-device preference, permissions." to:text];
    [self appendBullet:@"Personality — preset, formality, warmth, obedience, eeriness, verbosity, humor, idle observations, memory depth, refusal style." to:text];
    [self appendBullet:@"Simulation — scenario, tick rate, anomalies, automatic events, pod-bay override, mission clock, alerts, ambient hum." to:text];
    [self appendBullet:@"Intelligence — optional OpenAI-compatible or Ollama endpoint, model, Keychain API key, streaming, timeout, fallback." to:text];
    [self appendBullet:@"Advanced — export/import settings, export transcripts, diagnostics, clear conversation, reset, reveal support folder." to:text];

    [self appendHeading:@"Keyboard shortcuts" to:text];
    [self appendShortcut:@"⌘," description:@"Open Settings" to:text];
    [self appendShortcut:@"⌘?" description:@"Open this guide" to:text];
    [self appendShortcut:@"⌥Space" description:@"Start or stop listening" to:text];
    [self appendShortcut:@"⌘⇧L" description:@"Listen from the menu" to:text];
    [self appendShortcut:@"⌘." description:@"Stop speaking" to:text];
    [self appendShortcut:@"⌘⇧M" description:@"Mute or unmute" to:text];
    [self appendShortcut:@"⌘⇧D" description:@"Run diagnostics" to:text];
    [self appendShortcut:@"⌘⇧F" description:@"Cinema mode" to:text];
    [self appendShortcut:@"⌘⇧C" description:@"Compact mode" to:text];
    [self appendShortcut:@"⌘⇧S" description:@"Toggle the status sidebar" to:text];
    [self appendShortcut:@"⌘3" description:@"3D records" to:text];
    [self appendShortcut:@"⌘K" description:@"Clear the conversation" to:text];

    [self appendHeading:@"Privacy & safety" to:text];
    [self appendBody:@"HAL 9000 has no telemetry and makes no background network calls. The microphone is used only while listening; audio is never written to disk. In LLM mode, only text is sent to the endpoint you configure. API keys live in the macOS Keychain and are never exported or logged. Ship systems, pod-bay doors, diagnostics, and the deactivation sequence are fictional simulations." to:text];

    [self appendHeading:@"Troubleshooting" to:text];
    [self appendBullet:@"No voice — check the selected voice and volume in Settings → Voice, then press Preview. Some voices are downloaded separately in System Settings → Accessibility → Spoken Content." to:text];
    [self appendBullet:@"No microphone — check Privacy & Security → Microphone and Speech Recognition. After rebuilding an ad-hoc-signed app, reset with: tccutil reset Microphone com.sid.hal9000 and tccutil reset SpeechRecognition com.sid.hal9000." to:text];
    [self appendBullet:@"Launch at login unavailable — move HAL9000.app to /Applications and enable it again. The checkbox stays off when the system refuses registration." to:text];
    [self appendBullet:@"LLM errors — use Test Connection in Settings → Intelligence, or switch to Use Offline Mode. Scripted conversation works without any network." to:text];
    [self appendBullet:@"Safe mode — launch with --safe-mode to disable microphone, speech, and audio; --skip-boot bypasses the boot overlay." to:text];

    [self appendBody:@"Unofficial fan project. Original code and artwork; not affiliated with or endorsed by the rights holders of 2001: A Space Odyssey." to:text];

    textView.textStorage.attributedString = text;
}

- (void)appendIntro:(NSString *)string to:(NSMutableAttributedString *)text {
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.lineSpacing = 4.0;
    paragraph.paragraphSpacing = 6.0;
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:[string stringByAppendingString:@"\n"] attributes:@{
        NSFontAttributeName: [HALTheme uiFontOfSize:13 weight:NSFontWeightRegular],
        NSForegroundColorAttributeName: [HALTheme text],
        NSParagraphStyleAttributeName: paragraph
    }]];
}

- (void)appendHeading:(NSString *)string to:(NSMutableAttributedString *)text {
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.paragraphSpacingBefore = 20.0;
    paragraph.paragraphSpacing = 7.0;
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:[string.uppercaseString stringByAppendingString:@"\n"] attributes:@{
        NSFontAttributeName: [HALTheme monoFontOfSize:10 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: [HALTheme halRed],
        NSKernAttributeName: @0.9,
        NSParagraphStyleAttributeName: paragraph
    }]];
}

- (void)appendBody:(NSString *)string to:(NSMutableAttributedString *)text {
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.lineSpacing = 3.0;
    paragraph.paragraphSpacing = 8.0;
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:[string stringByAppendingString:@"\n"] attributes:@{
        NSFontAttributeName: [HALTheme uiFontOfSize:12 weight:NSFontWeightRegular],
        NSForegroundColorAttributeName: [HALTheme text],
        NSParagraphStyleAttributeName: paragraph
    }]];
}

- (void)appendBullet:(NSString *)string to:(NSMutableAttributedString *)text {
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.lineSpacing = 3.0;
    paragraph.paragraphSpacing = 4.0;
    paragraph.headIndent = 16.0;
    paragraph.firstLineHeadIndent = 4.0;
    NSString *line = [NSString stringWithFormat:@"•  %@\n", string];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:line attributes:@{
        NSFontAttributeName: [HALTheme uiFontOfSize:12 weight:NSFontWeightRegular],
        NSForegroundColorAttributeName: [HALTheme secondaryText],
        NSParagraphStyleAttributeName: paragraph
    }]];
}

- (void)appendShortcut:(NSString *)shortcut description:(NSString *)description to:(NSMutableAttributedString *)text {
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.paragraphSpacing = 4.0;
    paragraph.headIndent = 116.0;
    paragraph.firstLineHeadIndent = 4.0;
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@  %@\n", [shortcut stringByPaddingToLength:14 withString:@" " startingAtIndex:0], description] attributes:@{
        NSFontAttributeName: [HALTheme monoFontOfSize:10 weight:NSFontWeightRegular],
        NSForegroundColorAttributeName: [HALTheme text],
        NSParagraphStyleAttributeName: paragraph
    }]];
}

- (void)showHelp {
    [self showWindow:nil];
    [self.window center];
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)closePressed:(id)sender {
    [self.window close];
}

@end
