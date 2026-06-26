#import "HALKeychainStore.h"
#import <Security/Security.h>

static NSString * const HALKeychainServiceFallback = @"com.sid.hal9000";
static NSString * const HALKeychainAccount = @"llm-api-key";

@implementation HALKeychainStore

+ (instancetype)sharedStore {
    static HALKeychainStore *store = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[HALKeychainStore alloc] init];
    });
    return store;
}

- (NSString *)serviceName {
    return [NSBundle mainBundle].bundleIdentifier ?: HALKeychainServiceFallback;
}

- (NSMutableDictionary *)baseQuery {
    return [@{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: [self serviceName],
        (__bridge id)kSecAttrAccount: HALKeychainAccount
    } mutableCopy];
}

- (NSError *)errorWithStatus:(OSStatus)status operation:(NSString *)operation {
    NSString *message = CFBridgingRelease(SecCopyErrorMessageString(status, NULL)) ?: @"Unknown Keychain error";
    return [NSError errorWithDomain:@"com.sid.hal9000.keychain"
                               code:status
                           userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@ failed: %@", operation, message]}];
}

- (NSString *)apiKey:(NSError **)error {
    NSMutableDictionary *query = [self baseQuery];
    query[(__bridge id)kSecReturnData] = @YES;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;

    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status == errSecItemNotFound) {
        return nil;
    }
    if (status != errSecSuccess) {
        if (error) {
            *error = [self errorWithStatus:status operation:@"Reading API key"];
        }
        return nil;
    }
    NSData *data = CFBridgingRelease(result);
    if (![data isKindOfClass:[NSData class]]) {
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (BOOL)saveAPIKey:(NSString *)apiKey error:(NSError **)error {
    if (apiKey.length == 0) {
        return [self deleteAPIKey:error];
    }

    NSData *data = [apiKey dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *query = [self baseQuery];
    NSDictionary *changes = @{(__bridge id)kSecValueData: data};

    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)changes);
    if (status == errSecItemNotFound) {
        query[(__bridge id)kSecValueData] = data;
        query[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlock;
        status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    }

    if (status != errSecSuccess) {
        if (error) {
            *error = [self errorWithStatus:status operation:@"Saving API key"];
        }
        return NO;
    }
    return YES;
}

- (BOOL)deleteAPIKey:(NSError **)error {
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)[self baseQuery]);
    if (status == errSecSuccess || status == errSecItemNotFound) {
        return YES;
    }
    if (error) {
        *error = [self errorWithStatus:status operation:@"Deleting API key"];
    }
    return NO;
}

- (BOOL)hasAPIKey {
    NSMutableDictionary *query = [self baseQuery];
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    return SecItemCopyMatching((__bridge CFDictionaryRef)query, NULL) == errSecSuccess;
}

@end
