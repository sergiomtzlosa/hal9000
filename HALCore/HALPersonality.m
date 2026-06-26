#import "HALPersonality.h"
#import "HALConfiguration.h"

@implementation HALPersonality

+ (NSArray<NSString *> *)presetIdentifiers {
    return @[@"classic", @"attentive", @"unsettling", @"custom"];
}

+ (NSString *)displayNameForPreset:(NSString *)preset {
    if ([preset isEqualToString:@"attentive"]) return @"Attentive";
    if ([preset isEqualToString:@"unsettling"]) return @"Unsettling";
    if ([preset isEqualToString:@"custom"]) return @"Custom";
    return @"Classic";
}

+ (NSDictionary<NSString *, NSNumber *> *)traitsForPreset:(NSString *)preset {
    if ([preset isEqualToString:@"attentive"]) {
        return @{@"formality": @0.60, @"warmth": @0.65, @"obedience": @0.90,
                 @"eeriness": @0.20, @"verbosity": @0.55, @"humor": @0.35};
    }
    if ([preset isEqualToString:@"unsettling"]) {
        return @{@"formality": @0.85, @"warmth": @0.12, @"obedience": @0.35,
                 @"eeriness": @1.0, @"verbosity": @0.60, @"humor": @0.05};
    }
    return @{@"formality": @0.90, @"warmth": @0.25, @"obedience": @0.65,
             @"eeriness": @0.70, @"verbosity": @0.45, @"humor": @0.15};
}

+ (instancetype)personalityForConfiguration:(HALConfiguration *)configuration {
    HALPersonality *personality = [[HALPersonality alloc] init];
    personality.preset = configuration.personalityPreset;
    personality.addressAs = configuration.addressAs.length ? configuration.addressAs : configuration.userName;

    if ([personality.preset isEqualToString:@"custom"]) {
        personality.formality = configuration.formality;
        personality.warmth = configuration.warmth;
        personality.obedience = configuration.obedience;
        personality.eeriness = configuration.eeriness;
        personality.verbosity = configuration.verbosity;
        personality.humor = configuration.humor;
    } else {
        NSDictionary<NSString *, NSNumber *> *traits = [self traitsForPreset:personality.preset];
        personality.formality = traits[@"formality"].doubleValue;
        personality.warmth = traits[@"warmth"].doubleValue;
        personality.obedience = traits[@"obedience"].doubleValue;
        personality.eeriness = traits[@"eeriness"].doubleValue;
        personality.verbosity = traits[@"verbosity"].doubleValue;
        personality.humor = traits[@"humor"].doubleValue;
    }
    return personality;
}

- (NSString *)traitSummary {
    return [NSString stringWithFormat:@"formality %.2f, warmth %.2f, obedience %.2f, eeriness %.2f, verbosity %.2f, humor %.2f",
            self.formality, self.warmth, self.obedience, self.eeriness, self.verbosity, self.humor];
}

@end
