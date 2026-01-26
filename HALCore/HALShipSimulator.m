#import "HALShipSimulator.h"

NSNotificationName const HALShipSimulatorDidUpdateNotification = @"HALShipSimulatorDidUpdateNotification";

@interface HALShipSimulator ()
@property (nonatomic, strong) NSMutableArray<HALShipSystem *> *mutableSystems;
@property (nonatomic, strong) NSMutableArray<NSString *> *mutableEventLog;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSString *scenarioIdentifier;
@end

@implementation HALShipSimulator

- (instancetype)init {
    return [self initWithScenarioIdentifier:@"nominal"];
}

- (instancetype)initWithScenarioIdentifier:(NSString *)identifier {
    self = [super init];
    if (self) {
        _tickRate = 1.0;
        _missionStartDate = [NSDate date];
        _mutableEventLog = [NSMutableArray array];
        _mutableSystems = [NSMutableArray array];
        _scenarioIdentifier = identifier ?: @"nominal";
        _scenario = [HALScenario scenarioWithIdentifier:_scenarioIdentifier];
        [self buildSystemsForScenario:_scenarioIdentifier];
    }
    return self;
}

- (void)dealloc {
    [self.timer invalidate];
}

- (NSArray<HALShipSystem *> *)systems {
    return [self.mutableSystems copy];
}

- (NSArray<NSString *> *)eventLog {
    return [self.mutableEventLog copy];
}

- (HALShipSystem *)systemWithIdentifier:(NSString *)identifier {
    for (HALShipSystem *system in self.mutableSystems) {
        if ([system.identifier isEqualToString:identifier]) {
            return system;
        }
    }
    return nil;
}

- (HALShipSystem *)makeSystem:(NSString *)identifier name:(NSString *)name value:(NSString *)value detail:(NSString *)detail {
    HALShipSystem *system = [[HALShipSystem alloc] init];
    system.identifier = identifier;
    system.name = name;
    system.valueText = value;
    system.detail = detail;
    [self.mutableSystems addObject:system];
    return system;
}

- (void)buildSystemsForScenario:(NSString *)identifier {
    [self.mutableSystems removeAllObjects];
    [self.mutableEventLog removeAllObjects];

    HALShipSystem *core = [self makeSystem:@"core" name:@"AI Core" value:@"Online" detail:@"Logic memory center is stable."];
    core.numericValue = 100;
    core.unit = @"%";

    HALShipSystem *life = [self makeSystem:@"life" name:@"Life Support" value:@"20.9%" detail:@"Oxygen and CO₂ scrubbing nominal."];
    life.numericValue = 20.9;
    life.unit = @"% O₂";

    HALShipSystem *reactor = [self makeSystem:@"reactor" name:@"Reactor" value:@"98.2%" detail:@"Fusion reactor output stable."];
    reactor.numericValue = 98.2;
    reactor.unit = @"%";

    HALShipSystem *comms = [self makeSystem:@"comms" name:@"Communications" value:@"94%" detail:@"Deep-space uplink locked."];
    comms.numericValue = 94;
    comms.unit = @"%";

    [self makeSystem:@"nav" name:@"Navigation" value:@"Course locked" detail:@"Trajectory toward Jupiter is nominal."];
    [self makeSystem:@"ae35" name:@"AE-35 Unit" value:@"Aligned" detail:@"Antenna alignment unit responding."];
    [self makeSystem:@"podbay" name:@"Pod Bay Doors" value:@"Locked" detail:@"Pod bay access is restricted."];
    [self makeSystem:@"cryo" name:@"Cryo Bay" value:@"3 crew" detail:@"Crew hibernation stable."];

    HALShipSystem *hull = [self makeSystem:@"hull" name:@"Hull Integrity" value:@"100%" detail:@"No micrometeoroid damage detected."];
    hull.numericValue = 100;
    hull.unit = @"%";

    HALShipSystem *antenna = [self makeSystem:@"antenna" name:@"Antenna Array" value:@"87%" detail:@"Primary dish alignment good."];
    antenna.numericValue = 87;
    antenna.unit = @"%";

    if ([identifier isEqualToString:@"jupiter"]) {
        comms.numericValue = 71;
        comms.status = HALShipSystemStatusWarning;
        comms.detail = @"Long-range uplink degraded by Jupiter interference.";
        antenna.numericValue = 76;
        antenna.status = HALShipSystemStatusWarning;
        [self makeSystem:@"delay" name:@"Signal Delay" value:@"41 min" detail:@"Transmission delay to Earth."];
        [self addEvent:@"Jupiter interference detected on deep-space uplink."];
    } else if ([identifier isEqualToString:@"ae35"]) {
        HALShipSystem *ae35 = [self systemWithIdentifier:@"ae35"];
        ae35.valueText = @"Failure predicted";
        ae35.status = HALShipSystemStatusCritical;
        ae35.detail = @"Predicted failure in 72 hours. Replacement recommended.";
        comms.status = HALShipSystemStatusWarning;
        comms.numericValue = 88;
        [self addEvent:@"AE-35 unit failure prediction updated."];
    } else if ([identifier isEqualToString:@"podbay"]) {
        HALShipSystem *podbay = [self systemWithIdentifier:@"podbay"];
        podbay.status = HALShipSystemStatusCritical;
        podbay.valueText = @"Sealed";
        podbay.detail = @"Pod bay lockdown is active.";
        [self addEvent:@"Pod bay doors sealed by command authority."];
    } else if ([identifier isEqualToString:@"redalert"]) {
        life.status = HALShipSystemStatusWarning;
        life.numericValue = 19.4;
        reactor.status = HALShipSystemStatusCritical;
        reactor.numericValue = 61.0;
        comms.status = HALShipSystemStatusCritical;
        comms.numericValue = 22.0;
        hull.status = HALShipSystemStatusWarning;
        hull.numericValue = 82.0;
        antenna.status = HALShipSystemStatusCritical;
        antenna.numericValue = 34.0;
        [self addEvent:@"Red alert: multiple critical systems."];
    }
    [self.mutableSystems sortUsingComparator:^NSComparisonResult(HALShipSystem *a, HALShipSystem *b) {
        return [a.name compare:b.name];
    }];
}

- (void)setScenarioIdentifier:(NSString *)identifier {
    NSString *resolved = [[HALScenario allIdentifiers] containsObject:(identifier ?: @"")] ? identifier : @"nominal";
    _scenarioIdentifier = resolved;
    self.scenario = [HALScenario scenarioWithIdentifier:resolved];
    [self buildSystemsForScenario:resolved];
    [[NSNotificationCenter defaultCenter] postNotificationName:HALShipSimulatorDidUpdateNotification object:self];
}

- (void)start {
    [self.timer invalidate];
    if (self.tickRate <= 0.05) {
        self.tickRate = 1.0;
    }
    self.running = YES;
    self.timer = [NSTimer timerWithTimeInterval:self.tickRate target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)stop {
    [self.timer invalidate];
    self.timer = nil;
    self.running = NO;
}

- (void)timerFired:(NSTimer *)timer {
    [self tick];
}

- (void)tick {
    for (HALShipSystem *system in self.mutableSystems) {
        if (system.numericValue > 0 && system.status != HALShipSystemStatusOffline) {
            double drift = ((double)(arc4random_uniform(200)) - 100.0) / 100.0 * 0.25;
            system.numericValue = MAX(0, MIN(100, system.numericValue + drift));
            system.valueText = [system displayValue];
        }
        system.lastUpdated = [NSDate date];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:HALShipSimulatorDidUpdateNotification object:self];
}

- (NSInteger)warningCount {
    NSInteger count = 0;
    for (HALShipSystem *system in self.mutableSystems) {
        if (system.status == HALShipSystemStatusWarning || system.status == HALShipSystemStatusCritical) {
            count++;
        }
    }
    return count;
}

- (NSString *)statusSummary {
    NSMutableArray<NSString *> *warnings = [NSMutableArray array];
    for (HALShipSystem *system in self.mutableSystems) {
        if (system.status != HALShipSystemStatusNominal) {
            [warnings addObject:[NSString stringWithFormat:@"%@: %@ (%@)", system.name, [system displayValue], [system statusLabel].lowercaseString]];
        }
    }
    HALShipSystem *life = [self systemWithIdentifier:@"life"];
    if (warnings.count == 0) {
        return [NSString stringWithFormat:@"All systems are nominal. Life support is steady at %@.", [life displayValue]];
    }
    return [NSString stringWithFormat:@"I am monitoring %lu irregularit%@. %@", (unsigned long)warnings.count,
            warnings.count == 1 ? @"y" : @"ies", [warnings componentsJoinedByString:@"; "]];
}

- (NSString *)missionTimeString {
    NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:self.missionStartDate];
    NSInteger seconds = MAX(0, (NSInteger)elapsed);
    NSInteger days = seconds / 86400;
    NSInteger hours = (seconds % 86400) / 3600;
    NSInteger minutes = (seconds % 3600) / 60;
    NSInteger secs = seconds % 60;
    if (days > 0) {
        return [NSString stringWithFormat:@"T+%ldd %02ld:%02ld:%02ld", (long)days, (long)hours, (long)minutes, (long)secs];
    }
    return [NSString stringWithFormat:@"T+%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)secs];
}

- (NSString *)recentEventsSummary {
    if (self.mutableEventLog.count == 0) {
        return @"No significant events.";
    }
    return [[self.mutableEventLog subarrayWithRange:NSMakeRange(MAX(0, (NSInteger)self.mutableEventLog.count - 5), MIN(5, self.mutableEventLog.count))] componentsJoinedByString:@"\n"];
}

- (void)addEvent:(NSString *)event {
    if (!event) return;
    [self.mutableEventLog addObject:event];
    if (self.mutableEventLog.count > 50) {
        [self.mutableEventLog removeObjectAtIndex:0];
    }
}

- (void)runDiagnosticsWithCompletion:(void (^)(NSString *summary))completion {
    [self addEvent:@"Diagnostic sweep initiated."];
    [[NSNotificationCenter defaultCenter] postNotificationName:HALShipSimulatorDidUpdateNotification object:self];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSInteger warnings = [self warningCount];
        NSString *summary;
        if (warnings == 0) {
            summary = @"Diagnostic complete. All systems are functioning within normal parameters.";
        } else {
            summary = [NSString stringWithFormat:@"Diagnostic complete. I have detected %ld irregularit%@. %@", (long)warnings,
                       warnings == 1 ? @"y" : @"ies", [self statusSummary]];
        }
        [self addEvent:@"Diagnostic sweep complete."];
        [[NSNotificationCenter defaultCenter] postNotificationName:HALShipSimulatorDidUpdateNotification object:self];
        if (completion) completion(summary);
    });
}

- (void)setPodBayDoorsOpen:(BOOL)open {
    HALShipSystem *podbay = [self systemWithIdentifier:@"podbay"];
    podbay.valueText = open ? @"Open" : @"Locked";
    podbay.status = open ? HALShipSystemStatusWarning : HALShipSystemStatusNominal;
    podbay.detail = open ? @"Pod bay doors are open. This is a simulation." : @"Pod bay access is restricted.";
    [self addEvent:open ? @"Pod bay doors opened in simulation." : @"Pod bay doors sealed."];
    [[NSNotificationCenter defaultCenter] postNotificationName:HALShipSimulatorDidUpdateNotification object:self];
}

@end
