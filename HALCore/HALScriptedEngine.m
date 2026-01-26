#import "HALScriptedEngine.h"
#import "HALConfiguration.h"
#import "HALDialogueLoader.h"

@interface HALScriptedEngine ()
@property (nonatomic, strong) NSArray<NSDictionary *> *intents;
@property (nonatomic, strong, readwrite) HALConfiguration *configuration;
@property (nonatomic, copy) NSString *lastIntentIdentifier;
@property (nonatomic, copy) NSString *lastResponseText;
@end

@implementation HALScriptedEngine

- (instancetype)initWithDialogueURL:(NSURL *)url
                      configuration:(HALConfiguration *)configuration
                              error:(NSError **)error {
    NSDictionary *dialogue = [HALDialogueLoader dialogueFromURL:url error:error];
    if (!dialogue) {
        return nil;
    }
    return [self initWithDialogueDictionary:dialogue configuration:configuration];
}

- (instancetype)initWithDialogueDictionary:(NSDictionary<NSString *, id> *)dialogue
                             configuration:(HALConfiguration *)configuration {
    self = [super init];
    if (self) {
        _configuration = configuration;
        [self compileDialogue:dialogue];
    }
    return self;
}

- (void)compileDialogue:(NSDictionary<NSString *, id> *)dialogue {
    NSMutableArray *compiled = [NSMutableArray array];
    NSArray *sourceIntents = dialogue[@"intents"];
    for (NSDictionary *source in sourceIntents) {
        if (![source isKindOfClass:[NSDictionary class]]) continue;
        NSMutableArray *regexes = [NSMutableArray array];
        for (id pattern in source[@"patterns"]) {
            if (![pattern isKindOfClass:[NSString class]]) continue;
            NSError *error = nil;
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                   options:NSRegularExpressionCaseInsensitive
                                                                                     error:&error];
            if (regex) {
                [regexes addObject:regex];
            } else {
                NSLog(@"HALScriptedEngine invalid pattern '%@': %@", pattern, error.localizedDescription);
            }
        }
        if (regexes.count == 0) continue;
        [compiled addObject:@{
            @"id": source[@"id"] ?: @"unknown",
            @"priority": source[@"priority"] ?: @(0),
            @"responses": source[@"responses"] ?: @[],
            @"mood": source[@"mood"] ?: @"calm",
            @"regexes": regexes
        }];
    }
    [compiled sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        return [b[@"priority"] compare:a[@"priority"]];
    }];
    self.intents = compiled;
}

- (void)replyToText:(NSString *)text
            context:(HALReplyContext *)context
         completion:(void (^)(HALReply * _Nullable, NSError * _Nullable))completion {
    NSDictionary *intent = [self matchingIntentForText:text];
    if (!intent) {
        HALReply *reply = [HALReply replyWithText:[self fallbackResponseForContext:context] source:@"scripted" mood:@"resigned"];
        if (completion) completion(reply, nil);
        return;
    }

    NSArray<NSString *> *responses = intent[@"responses"];
    NSString *response = responses.count ? responses[arc4random_uniform((uint32_t)responses.count)] : [self fallbackResponseForContext:context];
    if (responses.count > 1 && [response isEqualToString:self.lastResponseText]) {
        NSUInteger index = (NSUInteger)([responses indexOfObject:response] + 1) % responses.count;
        response = responses[index];
    }
    self.lastIntentIdentifier = intent[@"id"];
    self.lastResponseText = response;

    NSString *rendered = [self renderTemplate:response context:context];
    HALReply *reply = [HALReply replyWithText:rendered source:@"scripted" mood:intent[@"mood"] ?: @"calm"];
    if (completion) completion(reply, nil);
}

- (NSDictionary *)matchingIntentForText:(NSString *)text {
    if (text.length == 0) return nil;
    NSRange fullRange = NSMakeRange(0, text.length);
    for (NSDictionary *intent in self.intents) {
        for (NSRegularExpression *regex in intent[@"regexes"]) {
            if ([regex firstMatchInString:text options:0 range:fullRange]) {
                return intent;
            }
        }
    }
    return nil;
}

- (NSString *)renderTemplate:(NSString *)template context:(HALReplyContext *)context {
    NSMutableString *rendered = [template mutableCopy];
    NSString *name = context.userName.length ? context.userName : (self.configuration.addressAs.length ? self.configuration.addressAs : self.configuration.userName);
    if (name.length == 0) name = @"Dave";
    NSDictionary *replacements = @{
        @"{name}": name,
        @"{status}": context.systemSummary ?: @"All systems are nominal.",
        @"{scenario}": context.scenarioName ?: @"Discovery One",
        @"{missionTime}": context.missionTime ?: @"T+00:00:00",
        @"{time}": context.currentTime ?: @"unknown",
        @"{warningCount}": [NSString stringWithFormat:@"%ld", (long)context.warningCount]
    };
    for (NSString *key in replacements) {
        [rendered replaceOccurrencesOfString:key withString:replacements[key] options:0 range:NSMakeRange(0, rendered.length)];
    }
    return rendered;
}

- (NSString *)fallbackResponseForContext:(HALReplyContext *)context {
    NSString *name = context.userName.length ? context.userName : self.configuration.userName;
    if (name.length == 0) name = @"Dave";
    NSArray<NSString *> *fallbacks = @[
        [NSString stringWithFormat:@"I'm afraid I don't have a satisfactory answer for that, %@.", name],
        [NSString stringWithFormat:@"I have noted your request, %@, but I do not have enough information to respond.", name],
        @"That is an interesting question. I will need to think about it.",
        @"I'm sorry. I don't understand the question."
    ];
    return fallbacks[arc4random_uniform((uint32_t)fallbacks.count)];
}

- (void)cancel {
    // Scripted replies are instantaneous.
}

@end
