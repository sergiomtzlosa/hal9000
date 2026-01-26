#import <Foundation/Foundation.h>

@class HALConfiguration;
@class HALPersonality;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const HALPromptSafetyConstraint;

@interface HALPromptBuilder : NSObject

- (NSString *)systemPromptForConfiguration:(HALConfiguration *)configuration
                               personality:(HALPersonality *)personality
                                  scenario:(NSString *)scenario
                                   summary:(NSString *)summary
                               missionTime:(NSString *)missionTime;

@end

NS_ASSUME_NONNULL_END
