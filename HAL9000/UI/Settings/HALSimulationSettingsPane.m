#import "HALSimulationSettingsPane.h"
#import "HALConfiguration.h"
#import "HALScenario.h"
#import "HALTheme.h"

@implementation HALSimulationSettingsPane

- (void)loadView {
    NSStackView *stack = [self scrollableStack];
    [stack addArrangedSubview:[self sectionTitle:@"Ship Simulation"]];
    [stack addArrangedSubview:[self helpText:@"Discovery One is simulated locally. No real hardware is accessed or controlled."]];

    NSMutableArray *scenarioOptions = [NSMutableArray array];
    for (HALScenario *scenario in [HALScenario allScenarios]) {
        [scenarioOptions addObject:@{@"title": scenario.name, @"value": scenario.identifier}];
    }
    NSPopUpButton *scenario = [self popupWithKey:@"scenario" options:scenarioOptions];
    [stack addArrangedSubview:[self rowWithLabel:@"Scenario" control:scenario]];
    [stack addArrangedSubview:[self helpText:@"Changing the scenario resets ship telemetry and HAL's status vocabulary."]];

    [self addSliderRowWithKey:@"tickRate" label:@"Simulator tick (s)" minimum:0.25 maximum:5.0];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Random telemetry drift" key:@"anomalies"]];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Scenario events fire automatically" key:@"autoEvents"]];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Allow pod bay door override (simulation only)" key:@"allowPodBayOverride"]];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Show the mission clock" key:@"missionClock"]];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Play alert and diagnostic cues" key:@"soundEffects"]];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Ambient ship hum" key:@"ambientHum"]];

    NSPopUpButton *sensitivity = [self popupWithKey:@"alertSensitivity" options:@[
        @{@"title": @"Low", @"value": @"low"},
        @{@"title": @"Normal", @"value": @"normal"},
        @{@"title": @"High", @"value": @"high"}
    ]];
    [stack addArrangedSubview:[self rowWithLabel:@"Alert sensitivity" control:sensitivity]];

    [stack addArrangedSubview:[self buttonWithTitle:@"Reset simulation" action:@selector(resetSimulation:)]];
    [stack addArrangedSubview:[self helpText:@"Pod bay requests are refused in character unless the override is enabled. Even then, nothing outside the simulation changes."]];
}

- (void)resetSimulation:(id)sender {
    self.configuration.scenario = @"nominal";
}

@end
