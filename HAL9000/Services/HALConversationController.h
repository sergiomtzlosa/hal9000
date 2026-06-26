#import <Foundation/Foundation.h>
#import "HALCore.h"
#import "HALSpeechSynthesizer.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HALConversationState) {
    HALConversationStateIdle = 0,
    HALConversationStateThinking,
    HALConversationStateSpeaking
};

@class HALConversationController;

@protocol HALConversationControllerDelegate <NSObject>
- (void)conversationController:(HALConversationController *)controller didAppendMessage:(HALMessage *)message;
- (void)conversationControllerDidBeginStreamingReply:(HALConversationController *)controller;
- (void)conversationController:(HALConversationController *)controller didUpdateStreamingReply:(NSString *)text;
- (void)conversationController:(HALConversationController *)controller didFinishReply:(HALMessage *)message;
- (void)conversationControllerDidCancelStreamingReply:(HALConversationController *)controller;
- (void)conversationController:(HALConversationController *)controller didChangeState:(HALConversationState)state;
- (void)conversationController:(HALConversationController *)controller performCommand:(HALCommand *)command;
- (void)conversationController:(HALConversationController *)controller didEncounterError:(NSError *)error;
@end

@interface HALConversationController : NSObject

@property (nonatomic, weak, nullable) id<HALConversationControllerDelegate> delegate;
@property (nonatomic, strong, readonly) HALConfiguration *configuration;
@property (nonatomic, strong, readonly) HALMemoryStore *memoryStore;
@property (nonatomic, strong, readonly) HALShipSimulator *simulator;
@property (nonatomic, strong, readonly) HALSpeechSynthesizer *speechSynthesizer;
@property (nonatomic, assign, readonly) HALConversationState state;
@property (nonatomic, assign, readonly, getter=isBusy) BOOL busy;
@property (nonatomic, assign) BOOL safeMode;

- (instancetype)initWithConfiguration:(HALConfiguration *)configuration
                          memoryStore:(HALMemoryStore *)memoryStore
                            simulator:(HALShipSimulator *)simulator
                     scriptedEngine:(HALScriptedEngine *)scriptedEngine
                  speechSynthesizer:(HALSpeechSynthesizer *)speechSynthesizer;

- (void)sendText:(NSString *)text;
- (void)cancelCurrentResponse;
- (void)appendHALMessage:(NSString *)text speak:(BOOL)speak;
- (void)emitIdleObservation;
- (void)clearConversation;

@end

NS_ASSUME_NONNULL_END
