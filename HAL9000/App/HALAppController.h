#import <Foundation/Foundation.h>
#import "HALConversationController.h"

NS_ASSUME_NONNULL_BEGIN

@interface HALAppController : NSObject <HALConversationControllerDelegate>

@property (nonatomic, assign, readonly) BOOL safeMode;

- (instancetype)initWithSafeMode:(BOOL)safeMode skipBoot:(BOOL)skipBoot;

- (void)start;
- (void)shutdown;

- (void)showMainWindow:(nullable id)sender;
- (void)showAbout:(nullable id)sender;
- (void)openSettings:(nullable id)sender;
- (void)openHelp:(nullable id)sender;
- (void)toggleListening:(nullable id)sender;
- (void)stopSpeaking:(nullable id)sender;
- (void)toggleMute:(nullable id)sender;
- (void)enterCinema:(nullable id)sender;
- (void)enterCompact:(nullable id)sender;
- (void)toggleSidebar:(nullable id)sender;
- (void)open3DViewer:(nullable id)sender;
- (void)clearConversation:(nullable id)sender;
- (void)runDiagnostics:(nullable id)sender;
- (void)exportTranscript:(nullable id)sender;
- (void)terminateFromMenu:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END
