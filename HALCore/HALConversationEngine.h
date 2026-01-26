#import <Foundation/Foundation.h>
#import "HALMessage.h"
#import "HALPersonality.h"

NS_ASSUME_NONNULL_BEGIN

@interface HALReply : NSObject
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *mood;
@property (nonatomic, copy) NSString *source;
+ (instancetype)replyWithText:(NSString *)text source:(NSString *)source mood:(NSString *)mood;
@end

@interface HALReplyContext : NSObject
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, copy) NSArray<HALMessage *> *recentMessages;
@property (nonatomic, copy) NSString *systemSummary;
@property (nonatomic, copy) NSString *scenarioName;
@property (nonatomic, copy) NSString *missionTime;
@property (nonatomic, copy) NSString *currentTime;
@property (nonatomic, assign) NSInteger warningCount;
@property (nonatomic, strong) HALPersonality *personality;
@end

@protocol HALConversationEngine <NSObject>
- (void)replyToText:(NSString *)text
            context:(HALReplyContext *)context
         completion:(void (^)(HALReply * _Nullable reply, NSError * _Nullable error))completion;
- (void)cancel;
@end

NS_ASSUME_NONNULL_END
