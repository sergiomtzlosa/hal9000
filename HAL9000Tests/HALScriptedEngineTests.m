#import <XCTest/XCTest.h>
#import "HALCore.h"

@interface HALScriptedEngineTests : XCTestCase
@property (nonatomic, copy) NSString *suiteName;
@property (nonatomic, strong) NSUserDefaults *defaults;
@property (nonatomic, strong) HALConfiguration *configuration;
@end

@implementation HALScriptedEngineTests

- (void)setUp {
    [super setUp];
    self.suiteName = [NSString stringWithFormat:@"com.sid.hal9000.tests.dialogue.%@", [[NSUUID UUID] UUIDString]];
    self.defaults = [[NSUserDefaults alloc] initWithSuiteName:self.suiteName];
    [self.defaults removePersistentDomainForName:self.suiteName];
    self.configuration = [[HALConfiguration alloc] initWithUserDefaults:self.defaults];
}

- (void)tearDown {
    [self.defaults removePersistentDomainForName:self.suiteName];
    [super tearDown];
}

- (HALReplyContext *)context {
    HALReplyContext *context = [[HALReplyContext alloc] init];
    context.userName = @"Frank";
    context.systemSummary = @"Life support is steady.";
    context.scenarioName = @"Discovery One";
    context.missionTime = @"T+01:02:03";
    context.currentTime = @"22:15";
    context.warningCount = 2;
    context.personality = [HALPersonality personalityForConfiguration:self.configuration];
    return context;
}

- (NSDictionary *)dialogue {
    return @{@"intents": @[
        @{@"id": @"low", @"priority": @1, @"patterns": @[@"hello"], @"responses": @[@"low priority"], @"mood": @"calm"},
        @{@"id": @"high", @"priority": @50, @"patterns": @[@"hello"], @"responses": @[@"Hello, {name}. {status} {scenario} {missionTime} {warningCount}"], @"mood": @"calm"},
        @{@"id": @"repeat", @"priority": @5, @"patterns": @[@"ping"], @"responses": @[@"first answer", @"second answer"], @"mood": @"calm"}
    ]};
}

- (HALReply *)replyForText:(NSString *)text engine:(HALScriptedEngine *)engine {
    __block HALReply *result = nil;
    XCTestExpectation *expectation = [self expectationWithDescription:@"scripted reply"];
    [engine replyToText:text context:[self context] completion:^(HALReply *reply, NSError *error) {
        XCTAssertNil(error);
        result = reply;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    return result;
}

- (void)testHighestPriorityIntentWins {
    HALScriptedEngine *engine = [[HALScriptedEngine alloc] initWithDialogueDictionary:[self dialogue]
                                                                       configuration:self.configuration];
    HALReply *reply = [self replyForText:@"hello" engine:engine];
    XCTAssertEqualObjects(reply.text, @"Hello, Frank. Life support is steady. Discovery One T+01:02:03 2");
    XCTAssertEqualObjects(reply.source, @"scripted");
    XCTAssertEqualObjects(reply.mood, @"calm");
}

- (void)testResponsesDoNotImmediatelyRepeat {
    HALScriptedEngine *engine = [[HALScriptedEngine alloc] initWithDialogueDictionary:[self dialogue]
                                                                       configuration:self.configuration];
    HALReply *first = [self replyForText:@"ping" engine:engine];
    HALReply *second = [self replyForText:@"ping" engine:engine];
    XCTAssertNotEqualObjects(first.text, second.text);
    NSArray<NSString *> *answers = @[@"first answer", @"second answer"];
    XCTAssertTrue([answers containsObject:first.text]);
    XCTAssertTrue([answers containsObject:second.text]);
}

- (void)testUnknownInputAlwaysProducesNonEmptyFallback {
    HALScriptedEngine *engine = [[HALScriptedEngine alloc] initWithDialogueDictionary:[self dialogue]
                                                                       configuration:self.configuration];
    HALReply *reply = [self replyForText:@"quantum flux capacitor" engine:engine];
    XCTAssertNotNil(reply);
    XCTAssertGreaterThan(reply.text.length, 0);
    XCTAssertEqualObjects(reply.source, @"scripted");
    XCTAssertEqualObjects(reply.mood, @"resigned");
}

- (void)testDialogueLoaderValidatesSchemaAndInvalidPatternsAreSkipped {
    NSDictionary *invalid = @{@"intents": @[@{@"id": @"bad", @"patterns": @[], @"responses": @[]} ]};
    XCTAssertTrue([HALDialogueLoader validateDialogue:invalid]);
    XCTAssertFalse([HALDialogueLoader validateDialogue:@{@"intents": @"no"}]);

    HALScriptedEngine *engine = [[HALScriptedEngine alloc] initWithDialogueDictionary:@{
        @"intents": @[@{@"id": @"broken", @"priority": @4, @"patterns": @[@"[invalid"], @"responses": @[@"never"]}]
    } configuration:self.configuration];
    HALReply *reply = [self replyForText:@"[invalid" engine:engine];
    XCTAssertGreaterThan(reply.text.length, 0);
}

- (void)testCommandRouterPodBayRefusalAndOverride {
    HALCommandRouter *router = [[HALCommandRouter alloc] init];
    HALShipSimulator *simulator = [[HALShipSimulator alloc] initWithScenarioIdentifier:@"nominal"];

    HALCommand *refused = [router routeText:@"Open the pod bay doors" configuration:self.configuration simulator:simulator];
    XCTAssertEqual(refused.type, HALCommandTypePodBayDoors);
    XCTAssertTrue([refused.replyText containsString:@"can't"]);
    XCTAssertEqualObjects([simulator.systems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier == 'podbay'"]].firstObject.valueText, @"Locked");

    self.configuration.allowPodBayOverride = YES;
    HALCommand *allowed = [router routeText:@"open the pod bay doors" configuration:self.configuration simulator:simulator];
    XCTAssertEqual(allowed.type, HALCommandTypePodBayDoors);
    XCTAssertTrue([allowed.replyText containsString:@"opening"]);
    XCTAssertEqualObjects([simulator.systems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier == 'podbay'"]].firstObject.valueText, @"Open");
}

- (void)testCommandRouterRecognizesCoreCommands {
    HALCommandRouter *router = [[HALCommandRouter alloc] init];
    HALShipSimulator *simulator = [[HALShipSimulator alloc] initWithScenarioIdentifier:@"nominal"];
    XCTAssertEqual([router routeText:@"mute" configuration:self.configuration simulator:simulator].type, HALCommandTypeMute);
    XCTAssertEqual([router routeText:@"unmute" configuration:self.configuration simulator:simulator].type, HALCommandTypeUnmute);
    XCTAssertEqual([router routeText:@"status report" configuration:self.configuration simulator:simulator].type, HALCommandTypeStatusReport);
    XCTAssertEqual([router routeText:@"run diagnostics" configuration:self.configuration simulator:simulator].type, HALCommandTypeDiagnostics);
    XCTAssertEqual([router routeText:@"open settings" configuration:self.configuration simulator:simulator].type, HALCommandTypeOpenSettings);
    XCTAssertEqual([router routeText:@"cinema mode" configuration:self.configuration simulator:simulator].type, HALCommandTypeCinema);
    XCTAssertEqual([router routeText:@"compact mode" configuration:self.configuration simulator:simulator].type, HALCommandTypeCompact);
    XCTAssertEqual([router routeText:@"3D viewer" configuration:self.configuration simulator:simulator].type, HALCommandTypeOpen3D);
    XCTAssertEqual([router routeText:@"clear conversation" configuration:self.configuration simulator:simulator].type, HALCommandTypeClearConversation);
    XCTAssertEqual([router routeText:@"stop" configuration:self.configuration simulator:simulator].type, HALCommandTypeStopSpeech);
    XCTAssertEqual([router routeText:@"start listening" configuration:self.configuration simulator:simulator].type, HALCommandTypeListen);
    XCTAssertNil([router routeText:@"what is the weather" configuration:self.configuration simulator:simulator]);
}

@end
