#import "HALSettingsPane.h"

@class HALMemoryStore;
@class HALShipSimulator;
@class HALSpeechSynthesizer;
@class HALSpeechRecognizer;

NS_ASSUME_NONNULL_BEGIN

@interface HALAdvancedSettingsPane : HALSettingsPane

@property (nonatomic, copy, nullable) void (^onClearConversation)(void);

- (instancetype)initWithConfiguration:(HALConfiguration *)configuration
                          memoryStore:(HALMemoryStore *)memoryStore
                            simulator:(HALShipSimulator *)simulator
                  speechSynthesizer:(HALSpeechSynthesizer *)speechSynthesizer
                         recognizer:(HALSpeechRecognizer *)recognizer;

@end

NS_ASSUME_NONNULL_END
