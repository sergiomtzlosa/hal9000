#import <XCTest/XCTest.h>
#import "HALCore.h"

@interface HALMemoryStoreTests : XCTestCase
@property (nonatomic, strong) NSURL *directory;
@end

@implementation HALMemoryStoreTests

- (void)setUp {
    [super setUp];
    self.directory = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES]
                      URLByAppendingPathComponent:[NSString stringWithFormat:@"HAL9000Tests-%@", [[NSUUID UUID] UUIDString]]
                      isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtURL:self.directory
                             withIntermediateDirectories:YES
                                              attributes:nil
                                                   error:NULL];
}

- (void)tearDown {
    [[NSFileManager defaultManager] removeItemAtURL:self.directory error:NULL];
    [super tearDown];
}

- (void)testAppendAndReloadFromDisk {
    HALMemoryStore *store = [[HALMemoryStore alloc] initWithBaseDirectory:self.directory];
    HALMessage *user = [HALMessage messageWithRole:HALMessageRoleUser text:@"Hello, HAL." engine:@"typed"];
    HALMessage *hal = [HALMessage messageWithRole:HALMessageRoleHAL text:@"Good evening." engine:@"scripted"];
    [store addMessage:user];
    [store addMessage:hal];

    XCTAssertEqual(store.messages.count, 2);
    HALMemoryStore *reloaded = [[HALMemoryStore alloc] initWithBaseDirectory:self.directory];
    XCTAssertEqual(reloaded.messages.count, 2);
    XCTAssertEqualObjects(reloaded.messages[0].text, @"Hello, HAL.");
    XCTAssertEqual(reloaded.messages[1].role, HALMessageRoleHAL);
    XCTAssertEqualObjects(reloaded.messages[1].engine, @"scripted");
}

- (void)testHistoryIsCappedAtFiveHundredMessages {
    HALMemoryStore *store = [[HALMemoryStore alloc] initWithBaseDirectory:self.directory];
    for (NSInteger i = 0; i < 505; i++) {
        [store addMessage:[HALMessage messageWithRole:HALMessageRoleUser text:[NSString stringWithFormat:@"%ld", (long)i] engine:@"test"]];
    }
    XCTAssertEqual(store.messages.count, 500);
    XCTAssertEqualObjects(store.messages.firstObject.text, @"5");
    XCTAssertEqualObjects(store.messages.lastObject.text, @"504");

    HALMemoryStore *reloaded = [[HALMemoryStore alloc] initWithBaseDirectory:self.directory];
    XCTAssertEqual(reloaded.messages.count, 500);
}

- (void)testCorruptConversationIsQuarantinedAndRecovered {
    HALMemoryStore *initial = [[HALMemoryStore alloc] initWithBaseDirectory:self.directory];
    [initial addMessage:[HALMessage messageWithRole:HALMessageRoleSystem text:@"Test" engine:@"test"]];
    NSURL *conversationURL = [self.directory URLByAppendingPathComponent:@"conversation.json"];
    [@"not valid JSON" writeToURL:conversationURL atomically:YES encoding:NSUTF8StringEncoding error:NULL];

    HALMemoryStore *reloaded = [[HALMemoryStore alloc] initWithBaseDirectory:self.directory];
    XCTAssertEqual(reloaded.messages.count, 0);

    NSArray<NSString *> *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.directory.path error:NULL];
    NSPredicate *corrupt = [NSPredicate predicateWithFormat:@"SELF BEGINSWITH 'conversation.corrupt-'"];
    XCTAssertEqual([contents filteredArrayUsingPredicate:corrupt].count, 1);
}

- (void)testClearAndExports {
    HALMemoryStore *store = [[HALMemoryStore alloc] initWithBaseDirectory:self.directory];
    [store addMessage:[HALMessage messageWithRole:HALMessageRoleUser text:@"Are you there?" engine:@"typed"]];
    [store addMessage:[HALMessage messageWithRole:HALMessageRoleHAL text:@"I am." engine:@"scripted"]];

    NSError *error = nil;
    NSData *jsonData = [store exportJSONData:&error];
    XCTAssertNotNil(jsonData);
    XCTAssertNil(error);
    id payload = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:NULL];
    XCTAssertEqualObjects(payload[@"messages"][1][@"text"], @"I am.");

    NSString *markdown = [store exportMarkdown];
    XCTAssertTrue([markdown containsString:@"HAL 9000"]);
    XCTAssertTrue([markdown containsString:@"Are you there?"]);

    [store clearMessages];
    XCTAssertEqual(store.messages.count, 0);
    XCTAssertEqual([[HALMemoryStore alloc] initWithBaseDirectory:self.directory].messages.count, 0);
}

@end
