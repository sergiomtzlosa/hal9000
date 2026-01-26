#import <Foundation/Foundation.h>

@class HALConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface HALSpeechRecognizer : NSObject

@property (nonatomic, strong) HALConfiguration *configuration;
@property (nonatomic, copy, nullable) void (^onPartialTranscript)(NSString *text);
@property (nonatomic, copy, nullable) void (^onFinalTranscript)(NSString *text);
@property (nonatomic, copy, nullable) void (^onError)(NSError *error);
@property (nonatomic, copy, nullable) void (^onListeningChanged)(BOOL listening);
@property (nonatomic, copy, nullable) void (^onLevel)(float level);
@property (nonatomic, assign, readonly, getter=isListening) BOOL listening;

- (void)requestPermissionsWithCompletion:(void (^)(BOOL granted, NSString *status))completion;
- (void)startListeningWithWakeMode:(BOOL)wakeMode;
- (void)stopListening;
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
