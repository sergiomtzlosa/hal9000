#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HALShipSystemStatus) {
    HALShipSystemStatusNominal = 0,
    HALShipSystemStatusWarning,
    HALShipSystemStatusCritical,
    HALShipSystemStatusOffline
};

@interface HALShipSystem : NSObject

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) HALShipSystemStatus status;
@property (nonatomic, copy) NSString *valueText;
@property (nonatomic, assign) double numericValue;
@property (nonatomic, copy) NSString *unit;
@property (nonatomic, assign) double normalMinimum;
@property (nonatomic, assign) double normalMaximum;
@property (nonatomic, copy) NSString *detail;
@property (nonatomic, strong) NSDate *lastUpdated;

- (NSString *)statusLabel;
- (NSString *)displayValue;

@end

NS_ASSUME_NONNULL_END
