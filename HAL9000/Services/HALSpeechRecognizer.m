#import "HALSpeechRecognizer.h"
#import "HALConfiguration.h"
#import <AVFoundation/AVFoundation.h>
#import <Speech/Speech.h>

@interface HALSpeechRecognizer ()
@property (nonatomic, strong) SFSpeechRecognizer *recognizer;
@property (nonatomic, strong) AVAudioEngine *audioEngine;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *request;
@property (nonatomic, strong) SFSpeechRecognitionTask *task;
@property (nonatomic, strong) NSTimer *silenceTimer;
@property (nonatomic, strong) NSTimer *maxTimer;
@property (nonatomic, copy) NSString *lastTranscript;
@property (nonatomic, assign) BOOL listening;
@property (nonatomic, assign) BOOL wakeMode;
@property (nonatomic, assign) BOOL awake;
@property (nonatomic, assign) BOOL deliveredFinal;
@property (nonatomic, assign) BOOL cancelled;
@property (nonatomic, assign) BOOL tapInstalled;
@end

@implementation HALSpeechRecognizer

- (void)requestPermissionsWithCompletion:(void (^)(BOOL, NSString *))completion {
    dispatch_group_t group = dispatch_group_create();
    __block BOOL micGranted = NO;
    __block BOOL speechGranted = NO;

    dispatch_group_enter(group);
    AVAuthorizationStatus micStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (micStatus == AVAuthorizationStatusAuthorized) {
        micGranted = YES;
        dispatch_group_leave(group);
    } else if (micStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            micGranted = granted;
            dispatch_group_leave(group);
        }];
    } else {
        dispatch_group_leave(group);
    }

    dispatch_group_enter(group);
    SFSpeechRecognizerAuthorizationStatus speechStatus = [SFSpeechRecognizer authorizationStatus];
    if (speechStatus == SFSpeechRecognizerAuthorizationStatusAuthorized) {
        speechGranted = YES;
        dispatch_group_leave(group);
    } else if (speechStatus == SFSpeechRecognizerAuthorizationStatusNotDetermined) {
        [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
            speechGranted = status == SFSpeechRecognizerAuthorizationStatusAuthorized;
            dispatch_group_leave(group);
        }];
    } else {
        dispatch_group_leave(group);
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSString *status;
        if (micGranted && speechGranted) {
            status = @"Microphone and speech recognition are authorized.";
        } else if (!micGranted && !speechGranted) {
            status = @"Microphone and speech recognition permissions were denied. Text input still works.";
        } else if (!micGranted) {
            status = @"Microphone permission was denied. Text input still works.";
        } else {
            status = @"Speech recognition permission was denied. Text input still works.";
        }
        if (completion) completion(micGranted && speechGranted, status);
    });
}

- (void)startListeningWithWakeMode:(BOOL)wakeMode {
    if (self.listening) {
        [self stopListening];
        return;
    }
    self.wakeMode = wakeMode;
    self.awake = !wakeMode;
    self.cancelled = NO;
    self.deliveredFinal = NO;
    self.lastTranscript = @"";
    self.configuration = self.configuration ?: [HALConfiguration sharedConfiguration];

    if (!self.configuration.listeningEnabled) {
        [self reportErrorWithMessage:@"Listening is disabled in Settings → Listening."];
        return;
    }

    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:self.configuration.speechLocale ?: @"en-US"];
    SFSpeechRecognizer *recognizer = [[SFSpeechRecognizer alloc] initWithLocale:locale];
    if (!recognizer || !recognizer.isAvailable) {
        [self reportErrorWithMessage:@"Speech recognition is not available for the selected language right now."];
        return;
    }
    self.recognizer = recognizer;

    self.audioEngine = [[AVAudioEngine alloc] init];
    AVAudioInputNode *input = self.audioEngine.inputNode;
    AVAudioFormat *format = [input outputFormatForBus:0];
    if (format.sampleRate <= 0 || format.channelCount == 0) {
        [self reportErrorWithMessage:@"No usable microphone input was found."];
        return;
    }

    self.request = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    self.request.shouldReportPartialResults = YES;
    if (self.configuration.onDevicePreferred && recognizer.supportsOnDeviceRecognition) {
        self.request.requiresOnDeviceRecognition = YES;
    }

    __weak typeof(self) weakSelf = self;
    self.task = [recognizer recognitionTaskWithRequest:self.request resultHandler:^(SFSpeechRecognitionResult *result, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (error) {
            if (!self.cancelled) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self handleRecognitionError:error];
                });
            }
            return;
        }
        if (!result) return;
        NSString *text = result.bestTranscription.formattedString ?: @"";
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleRecognitionText:text isFinal:result.isFinal];
        });
    }];

    [input installTapOnBus:0 bufferSize:1024 format:format block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self.request appendAudioPCMBuffer:buffer];
        float level = 0.0f;
        if (buffer.floatChannelData && buffer.frameLength > 0) {
            float *samples = buffer.floatChannelData[0];
            AVAudioFrameCount count = buffer.frameLength;
            double sum = 0;
            for (AVAudioFrameCount i = 0; i < count; i++) {
                sum += samples[i] * samples[i];
            }
            level = (float)sqrt(sum / (double)count);
        }
        if (self.onLevel) {
            dispatch_async(dispatch_get_main_queue(), ^{ self.onLevel(level); });
        }
    }];
    self.tapInstalled = YES;

    NSError *startError = nil;
    [self.audioEngine prepare];
    if (![self.audioEngine startAndReturnError:&startError]) {
        [self cleanupAudio];
        [self reportErrorWithMessage:startError.localizedDescription ?: @"Could not start the microphone."];
        return;
    }

    self.listening = YES;
    if (self.onListeningChanged) self.onListeningChanged(YES);
    [self resetSilenceTimer];
    [self.maxTimer invalidate];
    self.maxTimer = [NSTimer scheduledTimerWithTimeInterval:MAX(3.0, self.configuration.maxUtterance)
                                                     target:self
                                                   selector:@selector(maxDurationReached:)
                                                   userInfo:nil
                                                    repeats:NO];
}

- (void)handleRecognitionText:(NSString *)text isFinal:(BOOL)isFinal {
    if (self.cancelled) return;
    NSString *candidate = text ?: @"";
    if (self.wakeMode && !self.awake) {
        NSString *phrase = self.configuration.wakePhrase.length ? self.configuration.wakePhrase : @"HAL";
        NSRange range = [candidate.lowercaseString rangeOfString:phrase.lowercaseString];
        if (range.location != NSNotFound) {
            self.awake = YES;
            NSString *remainder = [[candidate substringFromIndex:NSMaxRange(range)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (remainder.length > 0) {
                self.lastTranscript = remainder;
                if (self.onPartialTranscript) self.onPartialTranscript(remainder);
            }
        }
        [self resetSilenceTimer];
        return;
    }

    self.lastTranscript = candidate;
    if (self.onPartialTranscript) self.onPartialTranscript(candidate);
    [self resetSilenceTimer];
    if (isFinal) {
        [self finishAndDeliver:YES];
    }
}

- (void)handleRecognitionError:(NSError *)error {
    if (self.cancelled) return;
    if (error.code == 203 || error.code == 1110) {
        // No speech detected; a normal end of utterance.
        [self finishAndDeliver:YES];
        return;
    }
    [self reportErrorWithMessage:error.localizedDescription ?: @"Speech recognition failed."];
    [self finishAndDeliver:NO];
}

- (void)resetSilenceTimer {
    [self.silenceTimer invalidate];
    if (!self.listening) return;
    NSTimeInterval timeout = MAX(0.6, self.configuration.silenceTimeout);
    self.silenceTimer = [NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(silenceTimeoutReached:) userInfo:nil repeats:NO];
}

- (void)silenceTimeoutReached:(NSTimer *)timer {
    if (self.lastTranscript.length > 0) {
        [self finishAndDeliver:YES];
    } else if (self.wakeMode && self.awake) {
        [self resetSilenceTimer];
    } else {
        [self finishAndDeliver:NO];
    }
}

- (void)maxDurationReached:(NSTimer *)timer {
    [self finishAndDeliver:YES];
}

- (void)finishAndDeliver:(BOOL)deliver {
    NSString *text = [self.lastTranscript stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    BOOL shouldDeliver = deliver && text.length > 0 && !self.deliveredFinal;
    self.deliveredFinal = YES;
    [self cleanupAudio];
    self.listening = NO;
    if (self.onListeningChanged) self.onListeningChanged(NO);
    if (shouldDeliver && self.onFinalTranscript) {
        self.onFinalTranscript(text);
    }
}

- (void)stopListening {
    [self finishAndDeliver:YES];
}

- (void)cancel {
    self.cancelled = YES;
    [self cleanupAudio];
    self.listening = NO;
    if (self.onListeningChanged) self.onListeningChanged(NO);
}

- (void)cleanupAudio {
    [self.silenceTimer invalidate];
    self.silenceTimer = nil;
    [self.maxTimer invalidate];
    self.maxTimer = nil;
    if (self.tapInstalled && self.audioEngine) {
        [self.audioEngine.inputNode removeTapOnBus:0];
        self.tapInstalled = NO;
    }
    if (self.audioEngine.isRunning) {
        [self.audioEngine stop];
    }
    [self.audioEngine reset];
    self.audioEngine = nil;
    [self.request endAudio];
    self.request = nil;
    [self.task cancel];
    self.task = nil;
}

- (void)reportErrorWithMessage:(NSString *)message {
    if (self.onError) {
        self.onError([NSError errorWithDomain:@"com.sid.hal9000.speech"
                                          code:500
                                      userInfo:@{NSLocalizedDescriptionKey: message ?: @"Speech recognition error"}]);
    }
}

@end
