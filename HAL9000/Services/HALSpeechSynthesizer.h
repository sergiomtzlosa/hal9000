#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

@class HALConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface HALSpeechSynthesizer : NSObject

@property (nonatomic, assign, getter=isMuted) BOOL muted;
@property (nonatomic, copy, nullable) void (^speakingChanged)(BOOL speaking);
@property (nonatomic, strong) HALConfiguration *configuration;

- (void)configureFromConfiguration:(HALConfiguration *)configuration;
- (NSArray<AVSpeechSynthesisVoice *> *)availableVoices;
@property (nonatomic, readonly) NSInteger cachedVoiceCount;
@property (nonatomic, readonly) BOOL voicesLoaded;
- (NSString *)displayNameForVoice:(AVSpeechSynthesisVoice *)voice;
- (void)speakText:(NSString *)text completion:(nullable void (^)(void))completion;
- (void)previewText:(NSString *)text completion:(nullable void (^)(void))completion;
- (void)stop;
- (BOOL)isSpeaking;

@end

NS_ASSUME_NONNULL_END
