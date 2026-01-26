#import "HALEyeView.h"
#import "HALTheme.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

@interface HALEyeView ()
@property (nonatomic, strong) NSTimer *animationTimer;
@property (nonatomic, assign) NSTimeInterval stateStartedAt;
@end

@implementation HALEyeView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        _state = HALEyeStateIdle;
        _eyeColor = [HALTheme halRed];
        _glowIntensity = 0.75;
        _pulseSpeed = 1.0;
        _eyeScale = 1.0;
        _scanlinesEnabled = YES;
        _grainEnabled = YES;
        _trackCursorEnabled = YES;
        _blinkEnabled = YES;
        _blinkInterval = 9.0;
        _reduceMotion = NO;
        _stateStartedAt = CACurrentMediaTime();
        self.wantsLayer = YES;
        self.layer.backgroundColor = NSColor.clearColor.CGColor;
        [self setAccessibilityElement:NO];
        [self updateAnimationTimer];
    }
    return self;
}

- (BOOL)isFlipped {
    return YES;
}

- (void)dealloc {
    [self.animationTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
    [super viewWillMoveToWindow:newWindow];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    if (self.window) {
        [center removeObserver:self name:nil object:self.window];
    }
    if (newWindow) {
        [center addObserver:self selector:@selector(windowVisibilityChanged:) name:NSWindowDidBecomeKeyNotification object:newWindow];
        [center addObserver:self selector:@selector(windowVisibilityChanged:) name:NSWindowDidResignKeyNotification object:newWindow];
        [center addObserver:self selector:@selector(windowVisibilityChanged:) name:NSWindowDidMiniaturizeNotification object:newWindow];
        [center addObserver:self selector:@selector(windowVisibilityChanged:) name:NSWindowDidDeminiaturizeNotification object:newWindow];
        [center addObserver:self selector:@selector(windowVisibilityChanged:) name:NSWindowDidChangeOcclusionStateNotification object:newWindow];
    }
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationActivityChanged:)
                                                 name:NSApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationActivityChanged:)
                                                 name:NSApplicationDidResignActiveNotification object:nil];
    if (self.window) {
        self.window.acceptsMouseMovedEvents = YES;
    }
    [self updateAnimationTimer];
}

- (BOOL)shouldAnimate {
    NSWindow *window = self.window;
    if (!window || !window.isVisible || window.isMiniaturized) return NO;
    if (!(window.occlusionState & NSWindowOcclusionStateVisible)) return NO;
    if (!NSApp.isActive || NSApp.isHidden) return NO;
    return YES;
}

- (void)updateAnimationTimer {
    BOOL shouldRun = [self shouldAnimate];
    if (shouldRun && !self.animationTimer) {
        // 20 fps is enough for the slow breathing/glow motion and is much
        // lighter than redrawing a large eye at 30 fps. The eye pauses when
        // its window is hidden, miniaturised, occluded, or the app is idle.
        NSTimeInterval interval = self.reduceMotion ? (1.0 / 8.0) : (1.0 / 20.0);
        __weak typeof(self) weakSelf = self;
        NSTimer *timer = [NSTimer timerWithTimeInterval:interval repeats:YES block:^(NSTimer *timer) {
            [weakSelf setNeedsDisplay:YES];
        }];
        timer.tolerance = interval * 0.2;
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        self.animationTimer = timer;
    } else if (!shouldRun && self.animationTimer) {
        [self.animationTimer invalidate];
        self.animationTimer = nil;
    }
    if (shouldRun) [self setNeedsDisplay:YES];
}

- (void)windowVisibilityChanged:(NSNotification *)notification {
    [self updateAnimationTimer];
}

- (void)applicationActivityChanged:(NSNotification *)notification {
    [self updateAnimationTimer];
}

- (void)setState:(HALEyeState)state animated:(BOOL)animated {
    if (_state == state) return;
    _state = state;
    self.stateStartedAt = CACurrentMediaTime();
    if (animated) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 0.25;
            self.animator.alphaValue = state == HALEyeStateOff ? 0.25 : 1.0;
        } completionHandler:nil];
    }
    [self setNeedsDisplay:YES];
}

- (void)setState:(HALEyeState)state {
    [self setState:state animated:YES];
}

- (void)setReduceMotion:(BOOL)reduceMotion {
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    [self.animationTimer invalidate];
    self.animationTimer = nil;
    [self updateAnimationTimer];
    [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)event {
    if (self.onClick) self.onClick();
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    CGContextRef ctx = NSGraphicsContext.currentContext.CGContext;
    NSRect bounds = self.bounds;
    CGFloat side = MIN(bounds.size.width, bounds.size.height);
    if (side < 20) return;

    CGFloat scale = MAX(0.65, MIN(1.35, self.eyeScale));
    CGFloat radius = side * 0.40 * scale;
    NSPoint center = NSMakePoint(NSMidX(bounds), NSMidY(bounds));

    NSTimeInterval now = CACurrentMediaTime();
    NSTimeInterval elapsed = now - self.stateStartedAt;
    double speed = MAX(0.2, self.pulseSpeed);
    double breath = self.reduceMotion ? 0.0 : sin(now * 1.35 * speed);
    double pulse = self.reduceMotion ? 0.0 : sin(now * 5.2 * speed);
    double blinkAmount = 0.0;

    if (self.blinkEnabled && !self.reduceMotion && self.state != HALEyeStateOff) {
        double interval = MAX(2.0, self.blinkInterval);
        double cycle = fmod(now, interval);
        if (cycle > interval - 0.22) {
            double t = (cycle - (interval - 0.22)) / 0.22;
            blinkAmount = sin(t * M_PI);
        }
    }

    if (self.trackCursorEnabled && !self.reduceMotion && self.window) {
        NSPoint mouse = [self convertPoint:[self.window mouseLocationOutsideOfEventStream] fromView:nil];
        CGFloat dx = MAX(-1.0, MIN(1.0, (mouse.x - center.x) / MAX(1.0, side * 0.5)));
        CGFloat dy = MAX(-1.0, MIN(1.0, (mouse.y - center.y) / MAX(1.0, side * 0.5)));
        center.x += dx * radius * 0.035;
        center.y += dy * radius * 0.035;
    }

    double glow = self.glowIntensity;
    double stateGlow = 1.0;
    NSColor *ringColor = nil;
    if (self.state == HALEyeStateOff) {
        glow = 0.02;
    } else if (self.state == HALEyeStateListening) {
        stateGlow = 0.85 + 0.15 * (self.reduceMotion ? 0.5 : pulse);
        ringColor = [HALTheme listening];
    } else if (self.state == HALEyeStateThinking) {
        stateGlow = 0.9 + 0.1 * (self.reduceMotion ? 0.5 : pulse);
    } else if (self.state == HALEyeStateSpeaking) {
        stateGlow = 0.9 + 0.18 * (self.reduceMotion ? 0.5 : pulse);
    } else if (self.state == HALEyeStateAlert) {
        stateGlow = 0.6 + 0.55 * (0.5 + 0.5 * sin(now * 8.0));
        ringColor = [HALTheme warning];
    } else if (self.state == HALEyeStateBoot) {
        double flicker = 0.45 + 0.55 * fabs(sin(now * 5.0)) * (0.4 + 0.6 * fmin(1.0, elapsed / 2.0));
        stateGlow = flicker;
    } else if (self.state == HALEyeStateMuted) {
        stateGlow = 0.28;
    }
    glow = MAX(0.0, MIN(1.4, glow * stateGlow * (1.0 + 0.04 * breath)));

    // Outer glow.
    NSColor *glowColor = [self.eyeColor colorWithAlphaComponent:0.25 * glow];
    NSColor *clearGlow = [self.eyeColor colorWithAlphaComponent:0.0];
    CGGradientRef glowGradient = CGGradientCreateWithColors(NULL,
        (__bridge CFArrayRef)@[(__bridge id)glowColor.CGColor, (__bridge id)clearGlow.CGColor], NULL);
    CGContextSaveGState(ctx);
    CGContextDrawRadialGradient(ctx, glowGradient, center, radius * 0.45, center, radius * 1.55, 0);
    CGGradientRelease(glowGradient);
    CGContextRestoreGState(ctx);

    // Outer housing / bezel.
    NSRect housing = NSMakeRect(center.x - radius * 1.13, center.y - radius * 1.13, radius * 2.26, radius * 2.26);
    CGContextSetFillColorWithColor(ctx, [NSColor colorWithWhite:0.025 alpha:1.0].CGColor);
    CGContextFillEllipseInRect(ctx, housing);

    NSRect bezel = NSMakeRect(center.x - radius * 1.04, center.y - radius * 1.04, radius * 2.08, radius * 2.08);
    CGContextSetStrokeColorWithColor(ctx, [NSColor colorWithWhite:0.18 alpha:1.0].CGColor);
    CGContextSetLineWidth(ctx, MAX(2.0, radius * 0.075));
    CGContextStrokeEllipseInRect(ctx, bezel);

    CGContextSetStrokeColorWithColor(ctx, [NSColor colorWithWhite:0.06 alpha:1.0].CGColor);
    CGContextSetLineWidth(ctx, MAX(1.0, radius * 0.03));
    CGContextStrokeEllipseInRect(ctx, NSInsetRect(bezel, radius * 0.075, radius * 0.075));

    // Bezel highlight.
    CGContextSetStrokeColorWithColor(ctx, [NSColor colorWithWhite:1.0 alpha:0.14].CGColor);
    CGContextSetLineWidth(ctx, MAX(1.0, radius * 0.012));
    CGContextAddArc(ctx, center.x, center.y, radius * 0.99, -M_PI * 0.88, -M_PI * 0.30, 0);
    CGContextStrokePath(ctx);

    // Lens.
    CGFloat openness = 1.0 - 0.78 * blinkAmount;
    CGFloat lensRadius = radius * 0.82 * openness;
    NSRect lensRect = NSMakeRect(center.x - lensRadius, center.y - lensRadius, lensRadius * 2.0, lensRadius * 2.0);
    NSColor *lensCore = [self.eyeColor blendedColorWithFraction:0.62 ofColor:[NSColor whiteColor]];
    NSColor *lensMid = self.eyeColor;
    NSColor *lensEdge = [self.eyeColor blendedColorWithFraction:0.82 ofColor:[NSColor blackColor]];
    CGGradientRef lensGradient = CGGradientCreateWithColors(NULL,
        (__bridge CFArrayRef)@[(__bridge id)lensCore.CGColor, (__bridge id)lensMid.CGColor, (__bridge id)lensEdge.CGColor, (__bridge id)[NSColor blackColor].CGColor],
        (CGFloat[]){0.0, 0.24, 0.72, 1.0});
    CGContextSaveGState(ctx);
    CGContextAddEllipseInRect(ctx, lensRect);
    CGContextClip(ctx);
    CGContextDrawRadialGradient(ctx, lensGradient, center, lensRadius * 0.05, center, lensRadius, 0);
    CGGradientRelease(lensGradient);

    // Concentric iris rings.
    for (int i = 1; i <= 5; i++) {
        CGFloat fraction = 0.18 + i * 0.13;
        CGContextSetStrokeColorWithColor(ctx, [self.eyeColor colorWithAlphaComponent:0.16 + 0.06 * (5 - i)].CGColor);
        CGContextSetLineWidth(ctx, MAX(0.6, radius * 0.006));
        CGContextStrokeEllipseInRect(ctx, NSMakeRect(center.x - lensRadius * fraction, center.y - lensRadius * fraction,
                                                     lensRadius * fraction * 2, lensRadius * fraction * 2));
    }

    // Aperture blades.
    CGFloat rotation = 0;
    if (self.state == HALEyeStateThinking && !self.reduceMotion) {
        rotation = now * 0.38;
    } else if (self.state == HALEyeStateListening && !self.reduceMotion) {
        rotation = sin(now * 0.65) * 0.10;
    }
    NSUInteger bladeCount = 12;
    CGFloat inner = lensRadius * 0.20;
    CGFloat outer = lensRadius * 0.88;
    for (NSUInteger i = 0; i < bladeCount; i++) {
        CGFloat start = rotation + (2.0 * M_PI * i) / bladeCount;
        CGFloat span = (2.0 * M_PI / bladeCount) * 0.86;
        CGMutablePathRef path = CGPathCreateMutable();
        CGPoint p1 = CGPointMake(center.x + cos(start) * outer, center.y + sin(start) * outer);
        CGPoint p2 = CGPointMake(center.x + cos(start + span) * outer, center.y + sin(start + span) * outer);
        CGPoint p3 = CGPointMake(center.x + cos(start + span * 0.56) * inner, center.y + sin(start + span * 0.56) * inner);
        CGPoint p4 = CGPointMake(center.x + cos(start + span * 0.12) * inner, center.y + sin(start + span * 0.12) * inner);
        CGPathMoveToPoint(path, NULL, p1.x, p1.y);
        CGPathAddLineToPoint(path, NULL, p2.x, p2.y);
        CGPathAddLineToPoint(path, NULL, p3.x, p3.y);
        CGPathAddLineToPoint(path, NULL, p4.x, p4.y);
        CGPathCloseSubpath(path);
        CGContextSetFillColorWithColor(ctx, [NSColor colorWithWhite:0.02 alpha:0.48].CGColor);
        CGContextAddPath(ctx, path);
        CGContextFillPath(ctx);
        CGContextSetStrokeColorWithColor(ctx, [self.eyeColor colorWithAlphaComponent:0.10].CGColor);
        CGContextSetLineWidth(ctx, MAX(0.5, radius * 0.004));
        CGContextAddPath(ctx, path);
        CGContextStrokePath(ctx);
        CGPathRelease(path);
    }

    // Pupil.
    CGFloat pupilRadius = lensRadius * (0.16 + 0.02 * (self.reduceMotion ? 0.5 : breath));
    NSColor *pupilCore = [NSColor colorWithSRGBRed:1.0 green:0.92 blue:0.84 alpha:0.98];
    NSColor *pupilEdge = [self.eyeColor colorWithAlphaComponent:0.02];
    CGGradientRef pupilGradient = CGGradientCreateWithColors(NULL,
        (__bridge CFArrayRef)@[(__bridge id)pupilCore.CGColor, (__bridge id)self.eyeColor.CGColor, (__bridge id)pupilEdge.CGColor], NULL);
    CGContextDrawRadialGradient(ctx, pupilGradient, center, 0, center, pupilRadius, 0);
    CGGradientRelease(pupilGradient);

    // Specular arc.
    CGContextSetStrokeColorWithColor(ctx, [NSColor colorWithWhite:1.0 alpha:0.18].CGColor);
    CGContextSetLineWidth(ctx, MAX(1.0, radius * 0.025));
    CGContextAddArc(ctx, center.x, center.y, lensRadius * 0.72, -M_PI * 0.80, -M_PI * 0.28, 0);
    CGContextStrokePath(ctx);

    // Scanlines and sensor grain.
    if (self.scanlinesEnabled) {
        CGContextSetStrokeColorWithColor(ctx, [NSColor colorWithWhite:1.0 alpha:0.035].CGColor);
        CGContextSetLineWidth(ctx, 1.0);
        for (CGFloat y = center.y - lensRadius; y < center.y + lensRadius; y += 4.0) {
            CGContextMoveToPoint(ctx, center.x - lensRadius, y);
            CGContextAddLineToPoint(ctx, center.x + lensRadius, y);
        }
        CGContextStrokePath(ctx);
    }
    if (self.grainEnabled) {
        for (int i = 0; i < 70; i++) {
            CGFloat a = (CGFloat)(i * 2.399963);
            CGFloat r = lensRadius * sqrt((CGFloat)(i % 17) / 17.0);
            CGFloat jitter = (CGFloat)((i * 37) % 11) / 11.0;
            CGFloat x = center.x + cos(a + now * 0.03) * r;
            CGFloat y = center.y + sin(a + now * 0.03) * r;
            CGContextSetFillColorWithColor(ctx, [NSColor colorWithWhite:1.0 alpha:0.02 + 0.03 * jitter].CGColor);
            CGContextFillRect(ctx, NSMakeRect(x, y, 1.2, 1.2));
        }
    }
    CGContextRestoreGState(ctx);

    // Listening / alert ring.
    if (ringColor) {
        CGContextSetStrokeColorWithColor(ctx, [ringColor colorWithAlphaComponent:0.55 + 0.25 * (self.reduceMotion ? 0.0 : pulse)].CGColor);
        CGContextSetLineWidth(ctx, MAX(1.0, radius * 0.018));
        CGContextStrokeEllipseInRect(ctx, NSInsetRect(bezel, -radius * 0.13, -radius * 0.13));
    }

    if (self.state == HALEyeStateMuted) {
        CGContextSetStrokeColorWithColor(ctx, [[NSColor colorWithWhite:0.9 alpha:0.7] colorWithAlphaComponent:0.7].CGColor);
        CGContextSetLineWidth(ctx, MAX(2.0, radius * 0.045));
        CGContextMoveToPoint(ctx, center.x - radius * 0.52, center.y + radius * 0.52);
        CGContextAddLineToPoint(ctx, center.x + radius * 0.52, center.y - radius * 0.52);
        CGContextStrokePath(ctx);
    }
}

@end
