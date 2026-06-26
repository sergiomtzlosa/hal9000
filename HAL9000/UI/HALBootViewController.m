#import "HALBootViewController.h"
#import "HALConfiguration.h"
#import "HALTheme.h"
#import "HALEyeView.h"

@interface HALBootViewController ()
@property (nonatomic, strong) HALConfiguration *configuration;
@property (nonatomic, copy) void (^completionBlock)(void);
@property (nonatomic, strong) HALEyeView *eyeView;
@property (nonatomic, strong) NSTextField *transcriptLabel;
@property (nonatomic, strong) NSTextField *skipLabel;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSArray<NSString *> *steps;
@property (nonatomic, assign) NSInteger stepIndex;
@property (nonatomic, assign) BOOL finished;
@end

@implementation HALBootViewController

- (instancetype)initWithConfiguration:(HALConfiguration *)configuration
                           completion:(void (^)(void))completion {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _configuration = configuration;
        _completionBlock = [completion copy];
        _steps = @[
            @"HAL 9000 SERIES ONLINE",
            @"CHECKING MEMORY BANKS… OK",
            @"VOICE SYNTHESIS CALIBRATED",
            @"ALL SYSTEMS NOMINAL",
            [NSString stringWithFormat:@"GOOD MORNING, %@.", configuration.addressAs.length ? configuration.addressAs.uppercaseString : configuration.userName.uppercaseString]
        ];
    }
    return self;
}

- (NSTextField *)labelWithString:(NSString *)string font:(NSFont *)font color:(NSColor *)color {
    NSTextField *label = [NSTextField labelWithString:string];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = font;
    label.textColor = color;
    return label;
}

- (void)loadView {
    NSView *root = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 900, 640)];
    root.wantsLayer = YES;
    root.layer.backgroundColor = [HALTheme background].CGColor;
    self.view = root;

    self.eyeView = [[HALEyeView alloc] initWithFrame:NSZeroRect];
    self.eyeView.translatesAutoresizingMaskIntoConstraints = NO;
    self.eyeView.state = HALEyeStateBoot;
    self.eyeView.eyeColor = [HALTheme colorFromHex:self.configuration.eyeColorHex];
    self.eyeView.glowIntensity = self.configuration.glowIntensity;
    self.eyeView.pulseSpeed = self.configuration.pulseSpeed;
    [root addSubview:self.eyeView];

    NSTextField *systemLabel = [self labelWithString:@"HAL 9000 · LOGIC MEMORY CENTER" font:[HALTheme monoFontOfSize:10 weight:NSFontWeightSemibold] color:[HALTheme secondaryText]];
    systemLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:systemLabel];

    self.transcriptLabel = [self labelWithString:@"" font:[HALTheme monoFontOfSize:10 weight:NSFontWeightRegular] color:[HALTheme text]];
    self.transcriptLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.transcriptLabel.maximumNumberOfLines = 0;
    self.transcriptLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.transcriptLabel.preferredMaxLayoutWidth = 360;
    [root addSubview:self.transcriptLabel];

    self.skipLabel = [self labelWithString:@"CLICK OR PRESS ESC TO SKIP" font:[HALTheme monoFontOfSize:8 weight:NSFontWeightMedium] color:[HALTheme secondaryText]];
    self.skipLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:self.skipLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.eyeView.centerXAnchor constraintEqualToAnchor:root.centerXAnchor],
        [self.eyeView.centerYAnchor constraintEqualToAnchor:root.centerYAnchor constant:-40],
        [self.eyeView.widthAnchor constraintEqualToConstant:300],
        [self.eyeView.heightAnchor constraintEqualToConstant:300],

        [systemLabel.leadingAnchor constraintEqualToAnchor:root.leadingAnchor constant:34],
        [systemLabel.topAnchor constraintEqualToAnchor:root.topAnchor constant:30],

        [self.transcriptLabel.leadingAnchor constraintEqualToAnchor:root.leadingAnchor constant:34],
        [self.transcriptLabel.bottomAnchor constraintEqualToAnchor:root.bottomAnchor constant:-58],
        [self.transcriptLabel.widthAnchor constraintEqualToConstant:420],

        [self.skipLabel.trailingAnchor constraintEqualToAnchor:root.trailingAnchor constant:-30],
        [self.skipLabel.bottomAnchor constraintEqualToAnchor:root.bottomAnchor constant:-28]
    ]];

    NSClickGestureRecognizer *click = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(skip)];
    [root addGestureRecognizer:click];
}

- (void)start {
    if (self.timer) return;
    self.stepIndex = 0;
    self.transcriptLabel.stringValue = @"";
    [self appendNextStep];
}

- (void)appendNextStep {
    if (self.finished) return;
    if (self.stepIndex >= (NSInteger)self.steps.count) {
        [self finish];
        return;
    }
    NSString *step = self.steps[self.stepIndex];
    NSString *existing = self.transcriptLabel.stringValue ?: @"";
    self.transcriptLabel.stringValue = existing.length ? [existing stringByAppendingFormat:@"\n> %@", step] : [NSString stringWithFormat:@"> %@", step];
    self.stepIndex++;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:(self.stepIndex == self.steps.count ? 1.0 : 0.55)
                                                  target:self
                                                selector:@selector(timerFired:)
                                                userInfo:nil
                                                 repeats:NO];
}

- (void)timerFired:(NSTimer *)timer {
    self.timer = nil;
    if (self.stepIndex >= (NSInteger)self.steps.count) {
        [self finish];
    } else {
        [self appendNextStep];
    }
}

- (void)skip {
    if (self.finished) return;
    [self finish];
}

- (void)finish {
    if (self.finished) return;
    self.finished = YES;
    [self.timer invalidate];
    self.timer = nil;
    self.eyeView.state = HALEyeStateIdle;
    if (self.completionBlock) self.completionBlock();
}

- (void)cancelOperation:(id)sender {
    [self skip];
}

- (void)dealloc {
    [self.timer invalidate];
}

@end
