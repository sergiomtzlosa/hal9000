#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HALMessageRole) {
    HALMessageRoleUser = 0,
    HALMessageRoleHAL = 1,
    HALMessageRoleSystem = 2
};

@interface HALMessage : NSObject

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, assign) HALMessageRole role;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) NSDate *timestamp;
@property (nonatomic, copy) NSString *engine;

+ (instancetype)messageWithRole:(HALMessageRole)role text:(NSString *)text engine:(NSString *)engine;

- (NSDictionary<NSString *, id> *)dictionaryRepresentation;
+ (nullable instancetype)messageFromDictionary:(NSDictionary<NSString *, id> *)dictionary;

- (NSString *)roleLabel;

@end

NS_ASSUME_NONNULL_END
