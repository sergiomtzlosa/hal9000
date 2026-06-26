#import <Cocoa/Cocoa.h>

@class HALConfiguration;
@class HALSpeechSynthesizer;
@class HALSpeechRecognizer;
@class HALMemoryStore;
@class HALShipSimulator;

NS_ASSUME_NONNULL_BEGIN

@interface HALSettingsWindowController : NSWindowController

@property (nonatomic, copy, nullable) void (^onClearConversation)(void);

- (instancetype)initWithConfiguration:(HALConfiguration *)configuration
                  speechSynthesizer:(HALSpeechSynthesizer *)speechSynthesizer
                         recognizer:(HALSpeechRecognizer *)recognizer
                        memoryStore:(HALMemoryStore *)memoryStore
                          simulator:(HALShipSimulator *)simulator;

- (void)showSettings;

@end

NS_ASSUME_NONNULL_END
