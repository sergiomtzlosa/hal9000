#import <Foundation/Foundation.h>

@class HALConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface HALPersonality : NSObject

@property (nonatomic, copy) NSString *preset;
@property (nonatomic, copy) NSString *addressAs;
@property (nonatomic, assign) double formality;
@property (nonatomic, assign) double warmth;
@property (nonatomic, assign) double obedience;
@property (nonatomic, assign) double eeriness;
@property (nonatomic, assign) double verbosity;
@property (nonatomic, assign) double humor;

+ (NSArray<NSString *> *)presetIdentifiers;
+ (NSString *)displayNameForPreset:(NSString *)preset;
+ (NSDictionary<NSString *, NSNumber *> *)traitsForPreset:(NSString *)preset;
+ (instancetype)personalityForConfiguration:(HALConfiguration *)configuration;

- (NSString *)traitSummary;

@end

NS_ASSUME_NONNULL_END
