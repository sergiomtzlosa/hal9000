#import "HALSettingsPane.h"

@class HALSpeechSynthesizer;

NS_ASSUME_NONNULL_BEGIN

@interface HALVoiceSettingsPane : HALSettingsPane

- (instancetype)initWithConfiguration:(HALConfiguration *)configuration
                  speechSynthesizer:(HALSpeechSynthesizer *)speechSynthesizer;

@end

NS_ASSUME_NONNULL_END
