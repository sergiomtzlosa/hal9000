#import "HALShipSystem.h"

@implementation HALShipSystem

- (instancetype)init {
    self = [super init];
    if (self) {
        _status = HALShipSystemStatusNominal;
        _valueText = @"";
        _detail = @"";
        _lastUpdated = [NSDate date];
    }
    return self;
}

- (NSString *)statusLabel {
    switch (self.status) {
        case HALShipSystemStatusNominal: return @"NOMINAL";
        case HALShipSystemStatusWarning: return @"WARNING";
        case HALShipSystemStatusCritical: return @"CRITICAL";
        case HALShipSystemStatusOffline: return @"OFFLINE";
    }
    return @"UNKNOWN";
}

- (NSString *)displayValue {
    if (self.unit.length > 0 && self.numericValue > 0) {
        return [NSString stringWithFormat:@"%.1f%@", self.numericValue, self.unit];
    }
    return self.valueText;
}

@end
