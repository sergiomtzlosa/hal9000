#import "HALConversationEngine.h"

@implementation HALReply

+ (instancetype)replyWithText:(NSString *)text source:(NSString *)source mood:(NSString *)mood {
    HALReply *reply = [[HALReply alloc] init];
    reply.text = text ?: @"";
    reply.source = source ?: @"scripted";
    reply.mood = mood ?: @"calm";
    return reply;
}

@end

@implementation HALReplyContext
@end
