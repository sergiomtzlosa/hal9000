#import "HALSSEParser.h"

@interface HALSSEParser ()
@property (nonatomic, strong) NSMutableData *buffer;
@end

@implementation HALSSEParser

- (instancetype)init {
    self = [super init];
    if (self) {
        _buffer = [NSMutableData data];
    }
    return self;
}

- (void)reset {
    [self.buffer setLength:0];
}

- (NSRange)nextEventSeparator {
    NSRange lf = [self.buffer rangeOfData:[@"\n\n" dataUsingEncoding:NSUTF8StringEncoding]
                                  options:0
                                    range:NSMakeRange(0, self.buffer.length)];
    NSRange crlf = [self.buffer rangeOfData:[@"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]
                                    options:0
                                      range:NSMakeRange(0, self.buffer.length)];
    if (lf.location == NSNotFound) return crlf;
    if (crlf.location == NSNotFound) return lf;
    return lf.location <= crlf.location ? lf : crlf;
}

- (NSArray<NSDictionary<NSString *, id> *> *)appendData:(NSData *)data {
    if (data.length == 0) return @[];
    [self.buffer appendData:data];

    NSMutableArray<NSDictionary<NSString *, id> *> *events = [NSMutableArray array];
    while (YES) {
        NSRange separator = [self nextEventSeparator];
        if (separator.location == NSNotFound) break;
        NSData *eventData = [self.buffer subdataWithRange:NSMakeRange(0, separator.location)];
        [self.buffer replaceBytesInRange:NSMakeRange(0, NSMaxRange(separator)) withBytes:NULL length:0];
        NSDictionary *event = [self parseEventData:eventData];
        if (event) [events addObject:event];
    }
    return events;
}

- (NSDictionary<NSString *, id> *)parseEventData:(NSData *)data {
    if (data.length == 0) return nil;
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!text) return nil;

    NSMutableArray<NSString *> *dataLines = [NSMutableArray array];
    for (NSString *line in [text componentsSeparatedByString:@"\n"]) {
        NSString *clean = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([clean hasPrefix:@"data:"]) {
            [dataLines addObject:[[clean substringFromIndex:5] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
        }
    }
    if (dataLines.count == 0) return nil;
    NSString *payload = [dataLines componentsJoinedByString:@"\n"];
    if ([payload isEqualToString:@"[DONE]"]) {
        return @{@"done": @YES};
    }
    NSData *payloadData = [payload dataUsingEncoding:NSUTF8StringEncoding];
    if (!payloadData) return nil;
    NSError *error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:payloadData options:0 error:&error];
    if ([object isKindOfClass:[NSDictionary class]]) {
        return object;
    }
    if ([object isKindOfClass:[NSArray class]]) {
        return @{@"events": object};
    }
    return nil;
}

@end
