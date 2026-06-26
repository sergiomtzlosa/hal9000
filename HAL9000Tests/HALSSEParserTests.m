#import <XCTest/XCTest.h>
#import "HALCore.h"

@interface HALSSEParserTests : XCTestCase
@property (nonatomic, strong) HALSSEParser *parser;
@end

@implementation HALSSEParserTests

- (void)setUp {
    [super setUp];
    self.parser = [[HALSSEParser alloc] init];
}

- (NSData *)data:(NSString *)string {
    return [string dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)testEventSplitAcrossArbitraryChunks {
    XCTAssertEqual([[self.parser appendData:[self data:@"data: {\"choices\":[{\"delta\":{\"content\":\"Hel"]] count], 0);
    NSArray *events = [self.parser appendData:[self data:@"lo\"}}]}\n\n"]];
    XCTAssertEqual(events.count, 1);
    XCTAssertEqualObjects(events.firstObject[@"choices"][0][@"delta"][@"content"], @"Hello");
}

- (void)testMultipleEventsAndDoneMarker {
    NSString *payload = @"data: {\"n\":1}\n\ndata: {\"n\":2}\n\ndata: [DONE]\n\n";
    NSArray *events = [self.parser appendData:[self data:payload]];
    XCTAssertEqual(events.count, 3);
    XCTAssertEqualObjects(events[0][@"n"], @1);
    XCTAssertEqualObjects(events[1][@"n"], @2);
    XCTAssertEqualObjects(events[2][@"done"], @YES);
}

- (void)testCRLFAndMultilineData {
    NSString *payload = @"data: {\"text\":\r\ndata: \"line\"}\r\n\r\n";
    NSArray *events = [self.parser appendData:[self data:payload]];
    XCTAssertEqual(events.count, 1);
    XCTAssertEqualObjects(events.firstObject[@"text"], @"line");
}

- (void)testMalformedAndCommentEventsAreIgnored {
    NSString *payload = @": keep-alive\n\ndata: not-json\n\ndata: {\"ok\":true}\n\n";
    NSArray *events = [self.parser appendData:[self data:payload]];
    XCTAssertEqual(events.count, 1);
    XCTAssertEqualObjects(events.firstObject[@"ok"], @YES);
}

- (void)testResetDropsPartialEvent {
    [self.parser appendData:[self data:@"data: {\"partial\":true"]];
    [self.parser reset];
    NSArray *events = [self.parser appendData:[self data:@"}\n\n"]];
    XCTAssertEqual(events.count, 0);
}

- (void)testArrayPayloadIsWrapped {
    NSArray *events = [self.parser appendData:[self data:@"data: [1,2,3]\n\n"]];
    XCTAssertEqual(events.count, 1);
    XCTAssertEqualObjects(events.firstObject[@"events"], (@[@1, @2, @3]));
}

@end
