#import <Cocoa/Cocoa.h>
#import "HALCore.h"

NS_ASSUME_NONNULL_BEGIN

@interface HALChatViewController : NSViewController

@property (nonatomic, copy, nullable) void (^onSendText)(NSString *text);
@property (nonatomic, copy, nullable) void (^onStop)(void);

- (void)appendMessage:(HALMessage *)message;
- (void)appendMessages:(NSArray<HALMessage *> *)messages;
- (void)beginStreamingHALReply;
- (void)updateStreamingText:(NSString *)text;
- (void)finishStreamingWithMessage:(HALMessage *)message;
- (void)cancelStreaming;
- (void)clearTranscript;
- (void)setInputEnabled:(BOOL)enabled;
- (void)focusInput;
- (void)setInputText:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
