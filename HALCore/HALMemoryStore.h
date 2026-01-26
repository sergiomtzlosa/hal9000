#import <Foundation/Foundation.h>
#import "HALMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface HALMemoryStore : NSObject

@property (nonatomic, strong, readonly) NSURL *baseDirectory;
@property (nonatomic, copy, readonly) NSArray<HALMessage *> *messages;

- (instancetype)init;
- (instancetype)initWithBaseDirectory:(NSURL *)baseDirectory NS_DESIGNATED_INITIALIZER;

- (void)load;
- (BOOL)save;
- (void)addMessage:(HALMessage *)message;
- (void)clearMessages;

- (NSData *)exportJSONData:(NSError **)error;
- (NSString *)exportMarkdown;

@end

NS_ASSUME_NONNULL_END
