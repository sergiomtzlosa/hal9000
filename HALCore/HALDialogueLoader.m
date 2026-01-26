#import "HALDialogueLoader.h"

@implementation HALDialogueLoader

+ (NSDictionary<NSString *, id> *)dialogueFromURL:(NSURL *)url error:(NSError **)error {
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:error];
    if (!data) {
        return nil;
    }
    NSError *jsonError = nil;
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    if (![object isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = jsonError ?: [NSError errorWithDomain:@"com.sid.hal9000.dialogue"
                                                      code:400
                                                  userInfo:@{NSLocalizedDescriptionKey: @"Dialogue file is not a JSON dictionary."}];
        }
        return nil;
    }
    NSDictionary *dialogue = object;
    if (![self validateDialogue:dialogue]) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.sid.hal9000.dialogue"
                                         code:422
                                     userInfo:@{NSLocalizedDescriptionKey: @"Dialogue file does not contain a valid intents array."}];
        }
        return nil;
    }
    return dialogue;
}

+ (BOOL)validateDialogue:(NSDictionary<NSString *, id> *)dialogue {
    id intents = dialogue[@"intents"];
    if (![intents isKindOfClass:[NSArray class]]) {
        return NO;
    }
    for (id intent in intents) {
        if (![intent isKindOfClass:[NSDictionary class]]) {
            return NO;
        }
        NSDictionary *dictionary = intent;
        if (![dictionary[@"id"] isKindOfClass:[NSString class]]) {
            return NO;
        }
        if (![dictionary[@"patterns"] isKindOfClass:[NSArray class]]) {
            return NO;
        }
        if (![dictionary[@"responses"] isKindOfClass:[NSArray class]]) {
            return NO;
        }
    }
    return YES;
}

@end
