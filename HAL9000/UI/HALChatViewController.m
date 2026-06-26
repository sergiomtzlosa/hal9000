#import "HALChatViewController.h"
#import "HALTheme.h"

@interface HALChatViewController () <NSTextFieldDelegate>
@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSTextView *textView;
@property (nonatomic, strong) NSTextField *inputField;
@property (nonatomic, strong) NSButton *sendButton;
@property (nonatomic, strong) NSButton *stopButton;
@property (nonatomic, assign) BOOL streaming;
@property (nonatomic, assign) NSUInteger streamingLocation;
@property (nonatomic, assign) NSUInteger streamingLength;
@property (nonatomic, assign) NSUInteger streamingStart;
@property (nonatomic, assign) BOOL scrollScheduled;
@property (nonatomic, strong) NSDateFormatter *timeFormatter;
@end

@implementation HALChatViewController

- (void)loadView {
    NSView *root = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 600, 360)];
    root.wantsLayer = YES;
    root.layer.backgroundColor = [HALTheme background].CGColor;
    self.view = root;

    self.scrollView = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.drawsBackground = NO;
    self.scrollView.hasVerticalScroller = YES;
    self.scrollView.autohidesScrollers = YES;
    self.scrollView.borderType = NSNoBorder;

    self.textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 600, 300)];
    self.textView.translatesAutoresizingMaskIntoConstraints = YES;
    self.textView.autoresizingMask = NSViewWidthSizable;
    self.textView.editable = NO;
    self.textView.selectable = YES;
    self.textView.richText = YES;
    self.textView.importsGraphics = NO;
    self.textView.drawsBackground = NO;
    self.textView.textColor = [HALTheme text];
    self.textView.font = [HALTheme uiFontOfSize:14 weight:NSFontWeightRegular];
    self.textView.textContainerInset = NSMakeSize(18, 18);
    self.textView.textContainer.widthTracksTextView = YES;
    self.textView.layoutManager.allowsNonContiguousLayout = YES;
    self.textView.minSize = NSMakeSize(0, 0);
    self.textView.maxSize = NSMakeSize(FLT_MAX, FLT_MAX);
    self.textView.verticallyResizable = YES;
    self.textView.horizontallyResizable = NO;
    self.scrollView.documentView = self.textView;

    NSView *inputBar = [[NSView alloc] initWithFrame:NSZeroRect];
    inputBar.translatesAutoresizingMaskIntoConstraints = NO;
    inputBar.wantsLayer = YES;
    inputBar.layer.backgroundColor = [HALTheme panel].CGColor;
    inputBar.layer.borderColor = [HALTheme line].CGColor;
    inputBar.layer.borderWidth = 1.0;

    self.inputField = [[NSTextField alloc] initWithFrame:NSZeroRect];
    self.inputField.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputField.delegate = self;
    self.inputField.target = self;
    self.inputField.action = @selector(sendPressed:);
    self.inputField.bezeled = NO;
    self.inputField.drawsBackground = YES;
    self.inputField.backgroundColor = [HALTheme colorFromHex:@"#0F1214"];
    self.inputField.textColor = [HALTheme text];
    self.inputField.font = [HALTheme uiFontOfSize:13 weight:NSFontWeightRegular];
    self.inputField.focusRingType = NSFocusRingTypeNone;
    self.inputField.placeholderString = @"Say something to HAL…";
    self.inputField.wantsLayer = YES;
    self.inputField.layer.cornerRadius = 7.0;
    self.inputField.layer.borderColor = [HALTheme line].CGColor;
    self.inputField.layer.borderWidth = 1.0;
    self.inputField.cell.usesSingleLineMode = YES;

    self.sendButton = [self buttonWithTitle:@"SEND" color:[HALTheme halRed] action:@selector(sendPressed:)];
    self.stopButton = [self buttonWithTitle:@"STOP" color:[HALTheme secondaryText] action:@selector(stopPressed:)];
    self.stopButton.hidden = YES;

    [inputBar addSubview:self.inputField];
    [inputBar addSubview:self.stopButton];
    [inputBar addSubview:self.sendButton];
    [root addSubview:self.scrollView];
    [root addSubview:inputBar];

    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:root.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:inputBar.topAnchor],

        [inputBar.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
        [inputBar.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
        [inputBar.bottomAnchor constraintEqualToAnchor:root.bottomAnchor],
        [inputBar.heightAnchor constraintEqualToConstant:62],

        [self.inputField.leadingAnchor constraintEqualToAnchor:inputBar.leadingAnchor constant:14],
        [self.inputField.centerYAnchor constraintEqualToAnchor:inputBar.centerYAnchor],
        [self.inputField.heightAnchor constraintEqualToConstant:36],
        [self.inputField.trailingAnchor constraintEqualToAnchor:self.stopButton.leadingAnchor constant:-8],

        [self.stopButton.centerYAnchor constraintEqualToAnchor:inputBar.centerYAnchor],
        [self.stopButton.widthAnchor constraintEqualToConstant:54],
        [self.stopButton.heightAnchor constraintEqualToConstant:30],
        [self.stopButton.trailingAnchor constraintEqualToAnchor:self.sendButton.leadingAnchor constant:-4],

        [self.sendButton.centerYAnchor constraintEqualToAnchor:inputBar.centerYAnchor],
        [self.sendButton.widthAnchor constraintEqualToConstant:62],
        [self.sendButton.heightAnchor constraintEqualToConstant:32],
        [self.sendButton.trailingAnchor constraintEqualToAnchor:inputBar.trailingAnchor constant:-14]
    ]];
}

- (NSButton *)buttonWithTitle:(NSString *)title color:(NSColor *)color action:(SEL)action {
    NSButton *button = [[NSButton alloc] initWithFrame:NSZeroRect];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.bordered = NO;
    button.target = self;
    button.action = action;
    button.wantsLayer = YES;
    button.layer.cornerRadius = 6.0;
    button.layer.backgroundColor = [color colorWithAlphaComponent:0.12].CGColor;
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment = NSTextAlignmentCenter;
    button.attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:@{
        NSFontAttributeName: [HALTheme monoFontOfSize:10 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: color,
        NSParagraphStyleAttributeName: paragraph
    }];
    return button;
}

- (void)sendPressed:(id)sender {
    NSString *text = [self.inputField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (text.length == 0) return;
    self.inputField.stringValue = @"";
    if (self.onSendText) self.onSendText(text);
}

- (void)stopPressed:(id)sender {
    if (self.onStop) self.onStop();
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    if ([[obj.userInfo objectForKey:@"NSTextMovement"] integerValue] == NSReturnTextMovement) {
        [self sendPressed:nil];
    }
}

- (NSDateFormatter *)timeFormatter {
    if (!_timeFormatter) {
        _timeFormatter = [[NSDateFormatter alloc] init];
        _timeFormatter.dateFormat = @"HH:mm:ss";
    }
    return _timeFormatter;
}

- (NSAttributedString *)attributedMessage:(HALMessage *)message {
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
    NSColor *roleColor = [HALTheme secondaryText];
    if (message.role == HALMessageRoleHAL) roleColor = [HALTheme halRed];
    else if (message.role == HALMessageRoleSystem) roleColor = [HALTheme warning];

    NSString *header = [NSString stringWithFormat:@"%@  %@\n", [message roleLabel], [self.timeFormatter stringFromDate:message.timestamp]];
    [result appendAttributedString:[[NSAttributedString alloc] initWithString:header attributes:@{
        NSFontAttributeName: [HALTheme monoFontOfSize:10 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: roleColor,
        NSKernAttributeName: @0.8
    }]];

    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.lineSpacing = 2.5;
    [result appendAttributedString:[[NSAttributedString alloc] initWithString:(message.text ?: @"") attributes:@{
        NSFontAttributeName: [HALTheme uiFontOfSize:14 weight:NSFontWeightRegular],
        NSForegroundColorAttributeName: message.role == HALMessageRoleSystem ? [HALTheme secondaryText] : [HALTheme text],
        NSParagraphStyleAttributeName: paragraph
    }]];
    [result appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n" attributes:@{
        NSFontAttributeName: [HALTheme uiFontOfSize:11 weight:NSFontWeightRegular]
    }]];
    return result;
}

- (void)appendMessage:(HALMessage *)message {
    if (!message) return;
    [self.textView.textStorage appendAttributedString:[self attributedMessage:message]];
    [self scrollToBottom];
}

- (void)appendMessages:(NSArray<HALMessage *> *)messages {
    if (messages.count == 0) return;
    [self.textView.textStorage beginEditing];
    for (HALMessage *message in messages) {
        if (!message) continue;
        [self.textView.textStorage appendAttributedString:[self attributedMessage:message]];
    }
    [self.textView.textStorage endEditing];
    [self scrollToBottom];
}

- (void)beginStreamingHALReply {
    [self cancelStreaming];
    NSMutableAttributedString *header = [[NSMutableAttributedString alloc] init];
    [header appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"HAL  %@\n", [self.timeFormatter stringFromDate:[NSDate date]]] attributes:@{
        NSFontAttributeName: [HALTheme monoFontOfSize:10 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: [HALTheme halRed],
        NSKernAttributeName: @0.8
    }]];
    self.streamingStart = self.textView.textStorage.length;
    [self.textView.textStorage appendAttributedString:header];
    self.streamingLocation = self.textView.textStorage.length;
    self.streamingLength = 0;
    self.streaming = YES;
    self.stopButton.hidden = NO;
    [self scrollToBottom];
}

- (NSAttributedString *)streamingAttributedText:(NSString *)text {
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.lineSpacing = 2.5;
    return [[NSAttributedString alloc] initWithString:(text ?: @"") attributes:@{
        NSFontAttributeName: [HALTheme uiFontOfSize:14 weight:NSFontWeightRegular],
        NSForegroundColorAttributeName: [HALTheme text],
        NSParagraphStyleAttributeName: paragraph
    }];
}

- (void)updateStreamingText:(NSString *)text {
    if (!self.streaming) [self beginStreamingHALReply];
    if (self.streamingLocation + self.streamingLength > self.textView.textStorage.length) {
        [self cancelStreaming];
        [self beginStreamingHALReply];
    }
    NSAttributedString *attributed = [self streamingAttributedText:text];
    [self.textView.textStorage replaceCharactersInRange:NSMakeRange(self.streamingLocation, self.streamingLength) withAttributedString:attributed];
    self.streamingLength = attributed.length;
    [self scrollToBottom];
}

- (void)finishStreamingWithMessage:(HALMessage *)message {
    if (self.streaming) {
        NSAttributedString *attributed = [self streamingAttributedText:message.text];
        if (self.streamingLocation + self.streamingLength <= self.textView.textStorage.length) {
            [self.textView.textStorage replaceCharactersInRange:NSMakeRange(self.streamingLocation, self.streamingLength) withAttributedString:attributed];
        }
        [self.textView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n" attributes:@{
            NSFontAttributeName: [HALTheme uiFontOfSize:11 weight:NSFontWeightRegular]
        }]];
        self.streaming = NO;
        self.streamingLength = 0;
        self.stopButton.hidden = YES;
        [self scrollToBottom];
    } else {
        [self appendMessage:message];
    }
}

- (void)cancelStreaming {
    if (!self.streaming) return;
    NSUInteger end = self.streamingLocation + self.streamingLength;
    if (end <= self.textView.textStorage.length && self.streamingStart <= end) {
        [self.textView.textStorage deleteCharactersInRange:NSMakeRange(self.streamingStart, end - self.streamingStart)];
    }
    self.streaming = NO;
    self.streamingLength = 0;
    self.stopButton.hidden = YES;
}

- (void)clearTranscript {
    [self.textView.textStorage setAttributedString:[[NSAttributedString alloc] initWithString:@""]];
    self.streaming = NO;
    [self scrollToBottom];
}

- (void)setInputEnabled:(BOOL)enabled {
    self.inputField.enabled = enabled;
    self.sendButton.enabled = enabled;
    self.stopButton.hidden = !self.streaming;
}

- (void)focusInput {
    [self.view.window makeFirstResponder:self.inputField];
}

- (void)setInputText:(NSString *)text {
    self.inputField.stringValue = text ?: @"";
    [self focusInput];
}

- (void)layoutTranscript {
    NSTextContainer *container = self.textView.textContainer;
    [self.textView.layoutManager ensureLayoutForTextContainer:container];
    NSRect used = [self.textView.layoutManager usedRectForTextContainer:container];
    NSSize viewport = self.scrollView.contentSize;
    CGFloat height = ceil(NSHeight(used) + self.textView.textContainerInset.height * 2.0);
    height = MAX(height, viewport.height);
    [self.textView setFrameSize:NSMakeSize(viewport.width, height)];
}

- (void)scrollToBottom {
    // Coalesce scroll requests. Restoring 200 messages, or a fast SSE reply,
    // can otherwise queue hundreds of full TextKit layouts on the main thread.
    if (self.scrollScheduled) return;
    self.scrollScheduled = YES;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.scrollScheduled = NO;
        [self layoutTranscript];
        NSUInteger length = self.textView.textStorage.length;
        if (length > 0) {
            [self.textView scrollRangeToVisible:NSMakeRange(length - 1, 1)];
            [self.scrollView reflectScrolledClipView:self.scrollView.contentView];
        }
    });
}

@end
