#import "HALSpeechSynthesizer.h"
#import "HALConfiguration.h"

@interface HALSpeechSynthesizer () <AVSpeechSynthesizerDelegate>
@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;
@property (nonatomic, copy) void (^completionBlock)(void);
@property (nonatomic, assign) BOOL previewing;
@property (atomic, strong, nullable) NSArray<AVSpeechSynthesisVoice *> *cachedVoices;
@end

@implementation HALSpeechSynthesizer

- (instancetype)init {
    self = [super init];
    if (self) {
        _synthesizer = [[AVSpeechSynthesizer alloc] init];
        _synthesizer.delegate = self;
        // Enumerating the installed system voices can take hundreds of
        // milliseconds on first use. Warm the cache on a background queue so
        // the first visit to Voice or Advanced settings never blocks the UI.
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            NSArray<AVSpeechSynthesisVoice *> *voices = [AVSpeechSynthesisVoice speechVoices];
            weakSelf.cachedVoices = voices;
        });
    }
    return self;
}

- (void)configureFromConfiguration:(HALConfiguration *)configuration {
    self.configuration = configuration;
}

- (BOOL)voicesLoaded {
    return self.cachedVoices != nil;
}

- (NSInteger)cachedVoiceCount {
    NSArray *voices = self.cachedVoices;
    return voices ? (NSInteger)voices.count : -1;
}

- (NSArray<AVSpeechSynthesisVoice *> *)availableVoices {
    NSArray<AVSpeechSynthesisVoice *> *voices = self.cachedVoices;
    if (!voices) {
        voices = [AVSpeechSynthesisVoice speechVoices];
        self.cachedVoices = voices;
    }
    NSMutableArray *filtered = [NSMutableArray array];
    for (AVSpeechSynthesisVoice *voice in voices) {
        if ([voice.language hasPrefix:@"en"] || [voice.identifier isEqualToString:self.configuration.voiceIdentifier]) {
            [filtered addObject:voice];
        }
    }
    [filtered sortUsingComparator:^NSComparisonResult(AVSpeechSynthesisVoice *a, AVSpeechSynthesisVoice *b) {
        return [a.name compare:b.name];
    }];
    return filtered;
}

- (NSString *)displayNameForVoice:(AVSpeechSynthesisVoice *)voice {
    NSString *quality = voice.quality == AVSpeechSynthesisVoiceQualityEnhanced ? @" · Enhanced" : @"";
    return [NSString stringWithFormat:@"%@ (%@)%@", voice.name, voice.language, quality];
}

- (AVSpeechSynthesisVoice *)selectedVoice {
    if (self.configuration.voiceIdentifier.length > 0) {
        AVSpeechSynthesisVoice *voice = [AVSpeechSynthesisVoice voiceWithIdentifier:self.configuration.voiceIdentifier];
        if (voice) return voice;
    }
    return [AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"];
}

- (void)speakText:(NSString *)text completion:(void (^)(void))completion {
    if (self.muted) {
        if (completion) completion();
        return;
    }
    [self speakText:text completion:completion bypassMute:NO];
}

- (void)previewText:(NSString *)text completion:(void (^)(void))completion {
    [self speakText:text completion:completion bypassMute:YES];
}

- (void)speakText:(NSString *)text completion:(void (^)(void))completion bypassMute:(BOOL)bypass {
    NSString *cleaned = [self cleanedText:text];
    if (cleaned.length == 0) {
        if (completion) completion();
        return;
    }
    if (self.muted && !bypass) {
        if (completion) completion();
        return;
    }
    if (self.synthesizer.isSpeaking) {
        [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }
    self.previewing = bypass;
    self.completionBlock = completion;

    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:cleaned];
    utterance.voice = [self selectedVoice];
    utterance.rate = MAX(0.1, MIN(1.0, self.configuration.voiceRate));
    utterance.pitchMultiplier = MAX(0.5, MIN(2.0, self.configuration.voicePitch));
    utterance.volume = MAX(0.0, MIN(1.0, self.configuration.voiceVolume));
    utterance.preUtteranceDelay = 0.06;
    utterance.postUtteranceDelay = 0.08;
    [self.synthesizer speakUtterance:utterance];
}

- (NSString *)cleanedText:(NSString *)text {
    if (text.length == 0) return @"";
    NSString *clean = [text stringByReplacingOccurrencesOfString:@"*" withString:@""];
    clean = [clean stringByReplacingOccurrencesOfString:@"#" withString:@""];
    clean = [clean stringByReplacingOccurrencesOfString:@"`" withString:@""];
    clean = [clean stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return clean;
}

- (void)stop {
    self.completionBlock = nil;
    [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    if (self.speakingChanged) self.speakingChanged(NO);
}

- (BOOL)isSpeaking {
    return self.synthesizer.isSpeaking;
}

- (void)finishCurrentSpeech {
    void (^completion)(void) = self.completionBlock;
    self.completionBlock = nil;
    if (self.speakingChanged) self.speakingChanged(NO);
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), completion);
    }
}

#pragma mark - AVSpeechSynthesizerDelegate

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance {
    if (self.speakingChanged) self.speakingChanged(YES);
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    [self finishCurrentSpeech];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance {
    [self finishCurrentSpeech];
}

@end
