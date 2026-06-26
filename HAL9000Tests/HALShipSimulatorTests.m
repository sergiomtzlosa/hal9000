#import <XCTest/XCTest.h>
#import "HALCore.h"

@interface HALShipSimulatorTests : XCTestCase
@end

@implementation HALShipSimulatorTests

- (void)testScenarioBaselinesAndWarnings {
    HALShipSimulator *nominal = [[HALShipSimulator alloc] initWithScenarioIdentifier:@"nominal"];
    XCTAssertEqual(nominal.warningCount, 0);
    XCTAssertTrue([nominal.statusSummary containsString:@"nominal"]);

    HALShipSimulator *jupiter = [[HALShipSimulator alloc] initWithScenarioIdentifier:@"jupiter"];
    XCTAssertGreaterThanOrEqual(jupiter.warningCount, 2);
    XCTAssertGreaterThan(jupiter.eventLog.count, 0);

    HALShipSimulator *ae35 = [[HALShipSimulator alloc] initWithScenarioIdentifier:@"ae35"];
    XCTAssertGreaterThanOrEqual(ae35.warningCount, 2);
    HALShipSystem *ae35System = [ae35.systems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier == 'ae35'"]].firstObject;
    XCTAssertEqual(ae35System.status, HALShipSystemStatusCritical);

    HALShipSimulator *podbay = [[HALShipSimulator alloc] initWithScenarioIdentifier:@"podbay"];
    XCTAssertGreaterThanOrEqual(podbay.warningCount, 1);

    HALShipSimulator *redalert = [[HALShipSimulator alloc] initWithScenarioIdentifier:@"redalert"];
    XCTAssertGreaterThanOrEqual(redalert.warningCount, 5);
    XCTAssertTrue([redalert.statusSummary containsString:@"irregularities"]);

    HALShipSimulator *single = [[HALShipSimulator alloc] initWithScenarioIdentifier:@"nominal"];
    HALShipSystem *comms = [single.systems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier == 'comms'"]].firstObject;
    comms.status = HALShipSystemStatusWarning;
    NSString *singleSummary = [single statusSummary];
    XCTAssertTrue([singleSummary containsString:@"1 irregularity."], @"Unexpected summary: %@", singleSummary);
    XCTAssertFalse([singleSummary containsString:@"irregularityies"]);
}

- (void)testUnknownScenarioFallsBackToNominal {
    HALShipSimulator *simulator = [[HALShipSimulator alloc] initWithScenarioIdentifier:@"does-not-exist"];
    XCTAssertEqualObjects(simulator.scenario.identifier, @"nominal");
    [simulator setScenarioIdentifier:@"also-not-real"];
    XCTAssertEqualObjects(simulator.scenario.identifier, @"nominal");
}

- (void)testTickAndMissionClockAreBounded {
    HALShipSimulator *simulator = [[HALShipSimulator alloc] initWithScenarioIdentifier:@"nominal"];
    [simulator tick];
    XCTAssertEqual(simulator.systems.count, 10);
    XCTAssertTrue([simulator.missionTimeString hasPrefix:@"T+"]);
    for (HALShipSystem *system in simulator.systems) {
        if (system.unit.length > 0) {
            XCTAssertGreaterThanOrEqual(system.numericValue, 0.0);
            XCTAssertLessThanOrEqual(system.numericValue, 100.0);
        }
        XCTAssertNotNil(system.lastUpdated);
    }
}

- (void)testPodBaySimulationChangesState {
    HALShipSimulator *simulator = [[HALShipSimulator alloc] initWithScenarioIdentifier:@"nominal"];
    HALShipSystem *podbay = [simulator.systems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier == 'podbay'"]].firstObject;
    XCTAssertEqualObjects(podbay.valueText, @"Locked");
    [simulator setPodBayDoorsOpen:YES];
    XCTAssertEqualObjects(podbay.valueText, @"Open");
    XCTAssertEqual(podbay.status, HALShipSystemStatusWarning);
    [simulator setPodBayDoorsOpen:NO];
    XCTAssertEqualObjects(podbay.valueText, @"Locked");
    XCTAssertEqual(podbay.status, HALShipSystemStatusNominal);
}

- (void)testDiagnosticsCompletesAndRecordsEvents {
    HALShipSimulator *simulator = [[HALShipSimulator alloc] initWithScenarioIdentifier:@"nominal"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"diagnostics"];
    [simulator runDiagnosticsWithCompletion:^(NSString *summary) {
        XCTAssertTrue([summary containsString:@"Diagnostic complete"]);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
    XCTAssertTrue([[simulator.eventLog componentsJoinedByString:@"\n"] containsString:@"Diagnostic sweep complete."]);
    XCTAssertEqual(simulator.warningCount, 0);
}

- (void)testScenarioChangeResetsTelemetry {
    HALShipSimulator *simulator = [[HALShipSimulator alloc] initWithScenarioIdentifier:@"nominal"];
    [simulator setScenarioIdentifier:@"redalert"];
    XCTAssertEqual(simulator.warningCount, 5);
    [simulator setScenarioIdentifier:@"nominal"];
    XCTAssertEqual(simulator.warningCount, 0);
    XCTAssertEqual(simulator.systems.count, 10);
}

@end
