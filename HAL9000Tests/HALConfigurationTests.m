#import <XCTest/XCTest.h>
#import "HALCore.h"

@interface HALConfigurationTests : XCTestCase
@property (nonatomic, copy) NSString *suiteName;
@property (nonatomic, strong) NSUserDefaults *defaults;
@property (nonatomic, strong) HALConfiguration *configuration;
@end

@implementation HALConfigurationTests

- (void)setUp {
    [super setUp];
    self.suiteName = [NSString stringWithFormat:@"com.sid.hal9000.tests.config.%@", [[NSUUID UUID] UUIDString]];
    self.defaults = [[NSUserDefaults alloc] initWithSuiteName:self.suiteName];
    [self.defaults removePersistentDomainForName:self.suiteName];
    self.configuration = [[HALConfiguration alloc] initWithUserDefaults:self.defaults];
}

- (void)tearDown {
    [self.defaults removePersistentDomainForName:self.suiteName];
    self.configuration = nil;
    self.defaults = nil;
    [super tearDown];
}

- (void)testDefaultsMatchTheDocumentedCatalogue {
    XCTAssertEqualObjects(self.configuration.userName, @"Dave");
    XCTAssertEqualObjects(self.configuration.startMode, @"standard");
    XCTAssertEqualObjects(self.configuration.eyeColorHex, @"#FF2A1A");
    XCTAssertEqualObjects(self.configuration.voiceCharacter, @"classic");
    XCTAssertEqualObjects(self.configuration.listeningMode, @"pushToTalk");
    XCTAssertEqualObjects(self.configuration.personalityPreset, @"classic");
    XCTAssertEqualObjects(self.configuration.scenario, @"nominal");
    XCTAssertEqualObjects(self.configuration.engine, @"scripted");
    XCTAssertEqualObjects(self.configuration.viewerQuality, @"high");
    XCTAssertTrue(self.configuration.bootSequence);
    XCTAssertTrue(self.configuration.autoSpeak);
    XCTAssertTrue(self.configuration.fallbackToScripted);
    XCTAssertFalse(self.configuration.viewerAutoRotate);
    XCTAssertEqualWithAccuracy(self.configuration.voiceRate, 0.42, 0.0001);
    XCTAssertEqualWithAccuracy(self.configuration.voicePitch, 0.82, 0.0001);
    XCTAssertEqual(self.configuration.maxTokens, 300);
    XCTAssertEqual(self.configuration.contextDepth, 20);
    XCTAssertEqual(self.configuration.schemaVersion, 1);
}

- (void)testSettersPersistAndSurviveAReinitialization {
    self.configuration.userName = @"Frank";
    self.configuration.engine = @"ollama";
    self.configuration.viewerAutoRotate = YES;
    self.configuration.eyeScale = 1.25;

    HALConfiguration *reloaded = [[HALConfiguration alloc] initWithUserDefaults:self.defaults];
    XCTAssertEqualObjects(reloaded.userName, @"Frank");
    XCTAssertEqualObjects(reloaded.engine, @"ollama");
    XCTAssertTrue(reloaded.viewerAutoRotate);
    XCTAssertEqualWithAccuracy(reloaded.eyeScale, 1.25, 0.0001);
}

- (void)testSettingValueForKeySupportsTheWholeCatalogue {
    NSArray<NSString *> *keys = [HALConfiguration allSettingKeys];
    XCTAssertGreaterThan(keys.count, 60);
    for (NSString *key in keys) {
        id value = [self.configuration settingValueForKey:key];
        XCTAssertNotNil(value, @"Missing default for key %@", key);
    }
    [self.configuration setSettingValue:@"Susan" forKey:@"userName"];
    XCTAssertEqualObjects([self.configuration settingValueForKey:@"userName"], @"Susan");
    [self.configuration setSettingValue:@"ignored" forKey:@"notARealSetting"];
    XCTAssertNil([self.configuration settingValueForKey:@"notARealSetting"]);
}

- (void)testChangeNotificationCarriesTheChangedKey {
    XCTestExpectation *expectation = [self expectationWithDescription:@"configuration change"];
    id token = [[NSNotificationCenter defaultCenter] addObserverForName:HALConfigurationDidChangeNotification
                                                                 object:self.configuration
                                                                  queue:[NSOperationQueue mainQueue]
                                                             usingBlock:^(NSNotification *note) {
        XCTAssertEqualObjects(note.userInfo[HALConfigurationChangedKeyKey], @"warmth");
        [expectation fulfill];
    }];
    self.configuration.warmth = 0.88;
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:token];
}

- (void)testExportImportRoundTripAndSchemaVersion {
    self.configuration.userName = @"Frank";
    self.configuration.warmth = 0.73;
    self.configuration.scenario = @"ae35";
    self.configuration.customInstructions = @"Keep the mission log concise.";
    self.configuration.viewerDeactivationSpeed = 1.6;
    NSDictionary *exported = [self.configuration exportSettings];
    XCTAssertEqualObjects(exported[@"schemaVersion"], @1);
    XCTAssertEqualObjects(exported[@"userName"], @"Frank");
    XCTAssertEqualObjects(exported[@"scenario"], @"ae35");
    XCTAssertNil(exported[@"apiKey"]);
    XCTAssertNil(exported[@"intelligence.apiKey"]);

    HALConfiguration *destination = [[HALConfiguration alloc] initWithUserDefaults:self.defaults];
    [destination resetToDefaults];
    NSError *error = nil;
    XCTAssertTrue([destination importSettings:exported error:&error], @"%@", error);
    XCTAssertEqualObjects(destination.userName, @"Frank");
    XCTAssertEqualWithAccuracy(destination.warmth, 0.73, 0.0001);
    XCTAssertEqualObjects(destination.scenario, @"ae35");
    XCTAssertEqualObjects(destination.customInstructions, @"Keep the mission log concise.");
    XCTAssertEqualWithAccuracy(destination.viewerDeactivationSpeed, 1.6, 0.0001);
}

- (void)testImportRejectsInvalidPayloadsAndWrongTypes {
    NSError *error = nil;
    XCTAssertFalse([self.configuration importSettings:(id)@[] error:&error]);
    XCTAssertNotNil(error);

    error = nil;
    XCTAssertFalse([self.configuration importSettings:@{@"userName": @42} error:&error]);
    XCTAssertNotNil(error);
}

- (void)testResetRestoresDefaults {
    self.configuration.userName = @"Frank";
    self.configuration.engine = @"ollama";
    [self.configuration resetToDefaults];
    XCTAssertEqualObjects(self.configuration.userName, @"Dave");
    XCTAssertEqualObjects(self.configuration.engine, @"scripted");
}

@end
