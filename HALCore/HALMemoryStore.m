#import "HALMemoryStore.h"

static const NSUInteger HALMemoryMaximumMessages = 500;

@interface HALMemoryStore ()
@property (nonatomic, strong, readwrite) NSURL *baseDirectory;
@property (nonatomic, strong) NSMutableArray<HALMessage *> *mutableMessages;
@property (nonatomic, strong) NSURL *conversationURL;
@end

@implementation HALMemoryStore

- (instancetype)init {
    NSURL *support = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory
                                                             inDomains:NSUserDomainMask] firstObject];
    NSURL *directory = [support URLByAppendingPathComponent:@"HAL9000" isDirectory:YES];
    return [self initWithBaseDirectory:directory];
}

- (instancetype)initWithBaseDirectory:(NSURL *)baseDirectory {
    self = [super init];
    if (self) {
        _baseDirectory = baseDirectory;
        _mutableMessages = [NSMutableArray array];
        _conversationURL = [baseDirectory URLByAppendingPathComponent:@"conversation.json"];
        [[NSFileManager defaultManager] createDirectoryAtURL:baseDirectory
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:NULL];
        [self load];
    }
    return self;
}

- (NSArray<HALMessage *> *)messages {
    return [self.mutableMessages copy];
}

- (void)load {
    NSData *data = [NSData dataWithContentsOfURL:self.conversationURL];
    if (!data) {
        return;
    }

    NSError *jsonError = nil;
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    if (![object isKindOfClass:[NSDictionary class]]) {
        [self quarantineCorruptFile];
        return;
    }

    NSArray *stored = ((NSDictionary *)object)[@"messages"];
    if (![stored isKindOfClass:[NSArray class]]) {
        [self quarantineCorruptFile];
        return;
    }

    [self.mutableMessages removeAllObjects];
    for (id item in stored) {
        HALMessage *message = [HALMessage messageFromDictionary:item];
        if (message) {
            [self.mutableMessages addObject:message];
        }
    }
    [self trim];
}

- (void)quarantineCorruptFile {
    NSString *name = [NSString stringWithFormat:@"conversation.corrupt-%lld.json", (long long)[[NSDate date] timeIntervalSince1970]];
    NSURL *destination = [self.baseDirectory URLByAppendingPathComponent:name];
    [[NSFileManager defaultManager] moveItemAtURL:self.conversationURL toURL:destination error:NULL];
    [self.mutableMessages removeAllObjects];
}

- (BOOL)save {
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:self.mutableMessages.count];
    for (HALMessage *message in self.mutableMessages) {
        [items addObject:[message dictionaryRepresentation]];
    }
    NSDictionary *payload = @{@"version": @1, @"messages": items};
    NSError *jsonError = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:payload options:NSJSONWritingPrettyPrinted error:&jsonError];
    if (!data) {
        NSLog(@"HALMemoryStore JSON error: %@", jsonError);
        return NO;
    }
    NSError *writeError = nil;
    BOOL success = [data writeToURL:self.conversationURL options:NSDataWritingAtomic error:&writeError];
    if (!success) {
        NSLog(@"HALMemoryStore write error: %@", writeError);
    }
    return success;
}

- (void)addMessage:(HALMessage *)message {
    if (!message) {
        return;
    }
    [self.mutableMessages addObject:message];
    [self trim];
    [self save];
}

- (void)trim {
    if (self.mutableMessages.count > HALMemoryMaximumMessages) {
        NSUInteger removeCount = self.mutableMessages.count - HALMemoryMaximumMessages;
        [self.mutableMessages removeObjectsInRange:NSMakeRange(0, removeCount)];
    }
}

- (void)clearMessages {
    [self.mutableMessages removeAllObjects];
    [self save];
}

- (NSData *)exportJSONData:(NSError **)error {
    NSMutableArray *items = [NSMutableArray array];
    for (HALMessage *message in self.mutableMessages) {
        [items addObject:[message dictionaryRepresentation]];
    }
    NSDictionary *payload = @{@"version": @1, @"exportedAt": @([[NSDate date] timeIntervalSince1970]), @"messages": items};
    return [NSJSONSerialization dataWithJSONObject:payload options:NSJSONWritingPrettyPrinted error:error];
}

- (NSString *)exportMarkdown {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;

    NSMutableString *markdown = [NSMutableString stringWithString:@"# HAL 9000 — Conversation Transcript\n\n"];
    [markdown appendFormat:@"Exported %@\n\n---\n\n", [formatter stringFromDate:[NSDate date]]];
    for (HALMessage *message in self.mutableMessages) {
        NSString *label = [message roleLabel];
        [markdown appendFormat:@"**%@** · %@\n\n%@\n\n---\n\n", label, [formatter stringFromDate:message.timestamp], message.text];
    }
    return markdown;
}

@end
