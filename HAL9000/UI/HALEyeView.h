#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HALEyeState) {
    HALEyeStateOff = 0,
    HALEyeStateBoot,
    HALEyeStateIdle,
    HALEyeStateListening,
    HALEyeStateThinking,
    HALEyeStateSpeaking,
    HALEyeStateAlert,
    HALEyeStateMuted
};

@interface HALEyeView : NSView

@property (nonatomic, assign) HALEyeState state;
@property (nonatomic, strong) NSColor *eyeColor;
@property (nonatomic, assign) double glowIntensity;
@property (nonatomic, assign) double pulseSpeed;
@property (nonatomic, assign) double eyeScale;
@property (nonatomic, assign) BOOL scanlinesEnabled;
@property (nonatomic, assign) BOOL grainEnabled;
@property (nonatomic, assign) BOOL trackCursorEnabled;
@property (nonatomic, assign) BOOL reduceMotion;
@property (nonatomic, assign) BOOL blinkEnabled;
@property (nonatomic, assign) double blinkInterval;
@property (nonatomic, copy, nullable) void (^onClick)(void);

- (void)setState:(HALEyeState)state animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
