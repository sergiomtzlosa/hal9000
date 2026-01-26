#import <XCTest/XCTest.h>
#import "HALCore.h"

@interface HALPromptBuilderTests : XCTestCase
@property (nonatomic, copy) NSString *suiteName;
@property (nonatomic, strong) NSUserDefaults *defaults;
@property (nonatomic, strong) HALConfiguration *configuration;
@property (nonatomic, strong) HALPromptBuilder *builder;
@end

@implementation HALPromptBuilderTests

- (void)setUp {
    [super setUp];
    self.suiteName = [NSString stringWithFormat:@"com.sid.hal9000.tests.prompt.%@", [[NSUUID UUID] UUIDString]];
    self.defaults = [[NSUserDefaults alloc] initWithSuiteName:self.suiteName];
    [self.defaults removePersistentDomainForName:self.suiteName];
    self.configuration = [[HALConfiguration alloc] initWithUserDefaults:self.defaults];
    self.builder = [[HALPromptBuilder alloc] init];
}

- (void)tearDown {
    [self.defaults removePersistentDomainForName:self.suiteName];
    [super tearDown];
}

- (void)testPromptContainsIdentityPersonalityScenarioAndSafety {
    self.configuration.userName = @"Frank";
    self.configuration.addressAs = @"Frank";
    self.configuration.personalityPreset = @"custom";
    self.configuration.formality = 0.55;
    self.configuration.warmth = 0.44;
    self.configuration.obedience = 0.33;
    self.configuration.eeriness = 0.22;
    self.configuration.verbosity = 0.11;
    self.configuration.humor = 0.66;
    HALPersonality *personality = [HALPersonality personalityForConfiguration:self.configuration];

    NSString *prompt = [self.builder systemPromptForConfiguration:self.configuration
                                                     personality:personality
                                                        scenario:@"AE-35 Failure"
                                                         summary:@"AE-35 is critical."
                                                     missionTime:@"T+03:04:05"];
    XCTAssertTrue([prompt containsString:@"You are HAL 9000"]);
    XCTAssertTrue([prompt containsString:@"Frank"]);
    XCTAssertTrue([prompt containsString:@"AE-35 Failure"]);
    XCTAssertTrue([prompt containsString:@"T+03:04:05"]);
    XCTAssertTrue([prompt containsString:@"formality 0.55"]);
    XCTAssertTrue([prompt containsString:@"warmth 0.44"]);
    XCTAssertTrue([prompt containsString:@"humor 0.66"]);
    XCTAssertTrue([prompt containsString:HALPromptSafetyConstraint]);
    XCTAssertFalse([prompt containsString:@"sk-"]);

    // The lower verbosity threshold should include the concise-reply instruction.
    XCTAssertTrue([prompt containsString:@"one or two sentences"]);
}

- (void)testCustomInstructionsAreAppendedBeforeSafety {
    self.configuration.customInstructions = @"Mention the mission clock when appropriate.";
    HALPersonality *personality = [HALPersonality personalityForConfiguration:self.configuration];
    NSString *prompt = [self.builder systemPromptForConfiguration:self.configuration
                                                     personality:personality
                                                        scenario:@"Nominal"
                                                         summary:@"Nominal."
                                                     missionTime:@"T+00:00:00"];
    XCTAssertTrue([prompt containsString:@"Mention the mission clock when appropriate."]);
    NSRange custom = [prompt rangeOfString:@"Mention the mission clock when appropriate."];
    NSRange safety = [prompt rangeOfString:HALPromptSafetyConstraint];
    XCTAssertNotEqual(custom.location, NSNotFound);
    XCTAssertNotEqual(safety.location, NSNotFound);
    XCTAssertLessThan(custom.location, safety.location);
}

- (void)testSystemPromptOverrideReplacesIdentityButKeepsContextAndSafety {
    self.configuration.systemPromptOverride = @"You are a silent mission computer. Answer in short fragments.";
    HALPersonality *personality = [HALPersonality personalityForConfiguration:self.configuration];
    NSString *prompt = [self.builder systemPromptForConfiguration:self.configuration
                                                     personality:personality
                                                        scenario:@"Red Alert"
                                                         summary:@"Five warnings."
                                                     missionTime:@"T+00:01:00"];
    XCTAssertTrue([prompt containsString:@"You are a silent mission computer."]);
    XCTAssertFalse([prompt containsString:@"You are HAL 9000"]);
    XCTAssertTrue([prompt containsString:@"Red Alert"]);
    XCTAssertTrue([prompt containsString:HALPromptSafetyConstraint]);
}

- (void)testAddressAsFallsBackToUserNameAndDave {
    self.configuration.addressAs = @"";
    self.configuration.userName = @"Frank";
    HALPersonality *personality = [HALPersonality personalityForConfiguration:self.configuration];
    NSString *prompt = [self.builder systemPromptForConfiguration:self.configuration
                                                     personality:personality
                                                        scenario:@"Nominal"
                                                         summary:@"Nominal."
                                                     missionTime:@"T+00:00:00"];
    XCTAssertTrue([prompt containsString:@"Frank"]);

    self.configuration.userName = @"";
    personality = [HALPersonality personalityForConfiguration:self.configuration];
    prompt = [self.builder systemPromptForConfiguration:self.configuration
                                            personality:personality
                                               scenario:@"Nominal"
                                                summary:@"Nominal."
                                            missionTime:@"T+00:00:00"];
    XCTAssertTrue([prompt containsString:@"Dave"]);
}

@end
