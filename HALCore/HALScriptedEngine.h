#import <Foundation/Foundation.h>
#import "HALConversationEngine.h"

@class HALConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface HALScriptedEngine : NSObject <HALConversationEngine>

@property (nonatomic, strong, readonly) HALConfiguration *configuration;

- (instancetype)initWithDialogueURL:(NSURL *)url
                      configuration:(HALConfiguration *)configuration
                              error:(NSError **)error;
- (instancetype)initWithDialogueDictionary:(NSDictionary<NSString *, id> *)dialogue
                             configuration:(HALConfiguration *)configuration;

@end

NS_ASSUME_NONNULL_END
