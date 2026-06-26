#import "HALSettingsPane.h"

@class HALSpeechRecognizer;

NS_ASSUME_NONNULL_BEGIN

@interface HALListeningSettingsPane : HALSettingsPane

- (instancetype)initWithConfiguration:(HALConfiguration *)configuration
                           recognizer:(HALSpeechRecognizer *)recognizer;

@end

NS_ASSUME_NONNULL_END
