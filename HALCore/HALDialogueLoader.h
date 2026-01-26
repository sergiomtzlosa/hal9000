#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HALDialogueLoader : NSObject

+ (nullable NSDictionary<NSString *, id> *)dialogueFromURL:(NSURL *)url error:(NSError **)error;
+ (BOOL)validateDialogue:(NSDictionary<NSString *, id> *)dialogue;

@end

NS_ASSUME_NONNULL_END
