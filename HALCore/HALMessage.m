#import "HALMessage.h"

@implementation HALMessage

+ (instancetype)messageWithRole:(HALMessageRole)role text:(NSString *)text engine:(NSString *)engine {
    HALMessage *message = [[HALMessage alloc] init];
    message.identifier = [[NSUUID UUID] UUIDString];
    message.role = role;
    message.text = text ?: @"";
    message.timestamp = [NSDate date];
    message.engine = engine ?: @"scripted";
    return message;
}

- (NSString *)roleLabel {
    switch (self.role) {
        case HALMessageRoleUser:
            return @"YOU";
        case HALMessageRoleHAL:
            return @"HAL";
        case HALMessageRoleSystem:
            return @"SYSTEM";
    }
    return @"SYSTEM";
}

- (NSDictionary<NSString *, id> *)dictionaryRepresentation {
    return @{
        @"id": self.identifier ?: [[NSUUID UUID] UUIDString],
        @"role": @(self.role),
        @"text": self.text ?: @"",
        @"timestamp": @([self.timestamp timeIntervalSince1970]),
        @"engine": self.engine ?: @"scripted"
    };
}

+ (instancetype)messageFromDictionary:(NSDictionary<NSString *, id> *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    id text = dictionary[@"text"];
    if (![text isKindOfClass:[NSString class]]) {
        return nil;
    }
    HALMessage *message = [[HALMessage alloc] init];
    id identifier = dictionary[@"id"];
    message.identifier = [identifier isKindOfClass:[NSString class]] ? identifier : [[NSUUID UUID] UUIDString];
    id role = dictionary[@"role"];
    message.role = [role isKindOfClass:[NSNumber class]] ? [role integerValue] : HALMessageRoleHAL;
    message.text = text;
    id timestamp = dictionary[@"timestamp"];
    message.timestamp = [timestamp isKindOfClass:[NSNumber class]] ? [NSDate dateWithTimeIntervalSince1970:[timestamp doubleValue]] : [NSDate date];
    id engine = dictionary[@"engine"];
    message.engine = [engine isKindOfClass:[NSString class]] ? engine : @"scripted";
    return message;
}

@end
