#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HALScenario : NSObject
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *summary;

+ (NSArray<HALScenario *> *)allScenarios;
+ (NSArray<NSString *> *)allIdentifiers;
+ (instancetype)scenarioWithIdentifier:(NSString *)identifier;
+ (NSString *)displayNameForIdentifier:(NSString *)identifier;
@end

NS_ASSUME_NONNULL_END
