#import <Foundation/Foundation.h>
#import "HALShipSystem.h"
#import "HALScenario.h"

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const HALShipSimulatorDidUpdateNotification;

@interface HALShipSimulator : NSObject

@property (nonatomic, copy) NSArray<HALShipSystem *> *systems;
@property (nonatomic, strong) HALScenario *scenario;
@property (nonatomic, copy) NSArray<NSString *> *eventLog;
@property (nonatomic, strong) NSDate *missionStartDate;
@property (nonatomic, assign) double tickRate;
@property (nonatomic, assign, getter=isRunning) BOOL running;

- (instancetype)initWithScenarioIdentifier:(NSString *)identifier NS_DESIGNATED_INITIALIZER;
- (instancetype)init;

- (void)start;
- (void)stop;
- (void)setScenarioIdentifier:(NSString *)identifier;
- (void)tick;

- (NSInteger)warningCount;
- (NSString *)statusSummary;
- (NSString *)missionTimeString;
- (NSString *)recentEventsSummary;

- (void)runDiagnosticsWithCompletion:(void (^)(NSString *summary))completion;
- (void)setPodBayDoorsOpen:(BOOL)open;

@end

NS_ASSUME_NONNULL_END
