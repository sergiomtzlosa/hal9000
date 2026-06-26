#import "HALScenario.h"

@implementation HALScenario

+ (NSArray<HALScenario *> *)allScenarios {
    NSArray *definitions = @[
        @[@"nominal", @"Discovery One — Nominal", @"All systems are within normal parameters."],
        @[@"jupiter", @"Jupiter Approach", @"Long-range communications are degraded and the antenna needs adjustment."],
        @[@"ae35", @"AE-35 Failure", @"The AE-35 unit is predicted to fail within seventy-two hours."],
        @[@"podbay", @"Pod Bay Lockdown", @"Pod bay access is restricted. The doors will not open."],
        @[@"redalert", @"Red Alert", @"Multiple systems are in a critical state."]
    ];
    NSMutableArray *scenarios = [NSMutableArray array];
    for (NSArray *definition in definitions) {
        HALScenario *scenario = [[HALScenario alloc] init];
        scenario.identifier = definition[0];
        scenario.name = definition[1];
        scenario.summary = definition[2];
        [scenarios addObject:scenario];
    }
    return scenarios;
}

+ (NSArray<NSString *> *)allIdentifiers {
    NSMutableArray *identifiers = [NSMutableArray array];
    for (HALScenario *scenario in [self allScenarios]) {
        [identifiers addObject:scenario.identifier];
    }
    return identifiers;
}

+ (instancetype)scenarioWithIdentifier:(NSString *)identifier {
    for (HALScenario *scenario in [self allScenarios]) {
        if ([scenario.identifier isEqualToString:identifier]) {
            return scenario;
        }
    }
    return [[self allScenarios] firstObject];
}

+ (NSString *)displayNameForIdentifier:(NSString *)identifier {
    return [[self scenarioWithIdentifier:identifier] name];
}

@end
