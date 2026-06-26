#import <Foundation/Foundation.h>

@class HALConfiguration;
@class HALShipSimulator;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HALCommandType) {
    HALCommandTypeNone = 0,
    HALCommandTypeMute,
    HALCommandTypeUnmute,
    HALCommandTypeStopSpeech,
    HALCommandTypeListen,
    HALCommandTypeOpenSettings,
    HALCommandTypeCinema,
    HALCommandTypeCompact,
    HALCommandTypeOpen3D,
    HALCommandTypeStatusReport,
    HALCommandTypeDiagnostics,
    HALCommandTypeClearConversation,
    HALCommandTypePodBayDoors,
    HALCommandTypeClosePodBayDoors,
    HALCommandTypeQuit
};

@interface HALCommand : NSObject
@property (nonatomic, assign) HALCommandType type;
@property (nonatomic, copy) NSString *replyText;
@property (nonatomic, copy) NSString *payload;
+ (instancetype)commandWithType:(HALCommandType)type reply:(NSString *)reply payload:(nullable NSString *)payload;
@end

@interface HALCommandRouter : NSObject

- (nullable HALCommand *)routeText:(NSString *)text
                     configuration:(HALConfiguration *)configuration
                         simulator:(HALShipSimulator *)simulator;

@end

NS_ASSUME_NONNULL_END
