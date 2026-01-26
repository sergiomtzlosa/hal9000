#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HALKeychainStore : NSObject

+ (instancetype)sharedStore;

- (nullable NSString *)apiKey:(NSError **)error;
- (BOOL)saveAPIKey:(NSString *)apiKey error:(NSError **)error;
- (BOOL)deleteAPIKey:(NSError **)error;
- (BOOL)hasAPIKey;

@end

NS_ASSUME_NONNULL_END
