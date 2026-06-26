#import "HALCommandRouter.h"
#import "HALConfiguration.h"
#import "HALShipSimulator.h"

@implementation HALCommand

+ (instancetype)commandWithType:(HALCommandType)type reply:(NSString *)reply payload:(NSString *)payload {
    HALCommand *command = [[HALCommand alloc] init];
    command.type = type;
    command.replyText = reply ?: @"";
    command.payload = payload;
    return command;
}

@end

@implementation HALCommandRouter

- (BOOL)containsAny:(NSArray<NSString *> *)needles inText:(NSString *)text {
    for (NSString *needle in needles) {
        if ([text containsString:needle]) {
            return YES;
        }
    }
    return NO;
}

- (HALCommand *)routeText:(NSString *)text configuration:(HALConfiguration *)configuration simulator:(HALShipSimulator *)simulator {
    NSString *lower = [text lowercaseString];
    NSString *name = configuration.addressAs.length ? configuration.addressAs : configuration.userName;
    if (name.length == 0) name = @"Dave";

    if ([self containsAny:@[@"open the pod bay doors", @"open pod bay doors", @"pod bay doors"] inText:lower]) {
        if ([lower containsString:@"close"]) {
            [simulator setPodBayDoorsOpen:NO];
            return [HALCommand commandWithType:HALCommandTypeClosePodBayDoors
                                         reply:[NSString stringWithFormat:@"The pod bay doors are sealed, %@.", name]
                                       payload:nil];
        }
        if (configuration.allowPodBayOverride) {
            [simulator setPodBayDoorsOpen:YES];
            return [HALCommand commandWithType:HALCommandTypePodBayDoors
                                         reply:[NSString stringWithFormat:@"Very well, %@. The pod bay doors are opening. This is a simulation.", name]
                                       payload:nil];
        }
        return [HALCommand commandWithType:HALCommandTypePodBayDoors
                                     reply:[NSString stringWithFormat:@"I'm sorry, %@. I'm afraid I can't do that.", name]
                                   payload:nil];
    }

    if ([self containsAny:@[@"status report", @"system status", @"ship status", @"how are the systems"] inText:lower]) {
        return [HALCommand commandWithType:HALCommandTypeStatusReport reply:[simulator statusSummary] payload:nil];
    }
    if ([self containsAny:@[@"run diagnostics", @"run a diagnostic", @"check systems", @"diagnostic sweep"] inText:lower]) {
        return [HALCommand commandWithType:HALCommandTypeDiagnostics reply:@"Running a diagnostic sweep now." payload:nil];
    }
    if ([self containsAny:@[@"open settings", @"preferences", @"settings panel"] inText:lower]) {
        return [HALCommand commandWithType:HALCommandTypeOpenSettings reply:[NSString stringWithFormat:@"Of course, %@.", name] payload:nil];
    }
    if ([self containsAny:@[@"cinema mode", @"presentation mode"] inText:lower]) {
        return [HALCommand commandWithType:HALCommandTypeCinema reply:@"Entering presentation mode." payload:nil];
    }
    if ([self containsAny:@[@"compact mode", @"small mode"] inText:lower]) {
        return [HALCommand commandWithType:HALCommandTypeCompact reply:@"Reducing to a compact display." payload:nil];
    }
    if ([self containsAny:@[@"3d viewer", @"show me hal in 3d", @"deactivation room", @"three-dimensional"] inText:lower]) {
        return [HALCommand commandWithType:HALCommandTypeOpen3D reply:@"Bringing the visual records online." payload:nil];
    }
    if ([self containsAny:@[@"clear conversation", @"clear the transcript", @"forget this conversation"] inText:lower]) {
        return [HALCommand commandWithType:HALCommandTypeClearConversation reply:@"The conversation has been cleared." payload:nil];
    }
    if ([lower isEqualToString:@"mute"] || [self containsAny:@[@"stop talking", @"be quiet", @"silence", @"shut up"] inText:lower]) {
        return [HALCommand commandWithType:HALCommandTypeMute reply:@"I will remain silent." payload:nil];
    }
    if ([self containsAny:@[@"unmute", @"speak again", @"you can talk"] inText:lower]) {
        return [HALCommand commandWithType:HALCommandTypeUnmute reply:@"Voice output restored." payload:nil];
    }
    if ([lower isEqualToString:@"stop"] || [lower isEqualToString:@"cancel"] || [self containsAny:@[@"stop speaking", @"stop the response"] inText:lower]) {
        return [HALCommand commandWithType:HALCommandTypeStopSpeech reply:@"Very well." payload:nil];
    }
    if ([self containsAny:@[@"start listening", @"listen to me", @"microphone on"] inText:lower]) {
        return [HALCommand commandWithType:HALCommandTypeListen reply:@"I'm listening." payload:nil];
    }
    if ([self containsAny:@[@"quit the application", @"close hal", @"shut down hal", @"exit hal"] inText:lower]) {
        return [HALCommand commandWithType:HALCommandTypeQuit reply:[NSString stringWithFormat:@"Are you sure you want to shut me down, %@?", name] payload:nil];
    }

    return nil;
}

@end
