#import <Cocoa/Cocoa.h>
#import "HALCore.h"
#import "HALEyeView.h"
#import "HALChatViewController.h"
#import "HALStatusSidebarViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface HALMainViewController : NSViewController

@property (nonatomic, strong, readonly) HALEyeView *eyeView;
@property (nonatomic, strong, readonly) HALChatViewController *chatViewController;
@property (nonatomic, strong, readonly) HALStatusSidebarViewController *sidebarViewController;
@property (nonatomic, assign, readonly, getter=isCompactMode) BOOL compactMode;
@property (nonatomic, assign, readonly, getter=isSidebarVisible) BOOL sidebarVisible;

@property (nonatomic, copy, nullable) void (^onSendText)(NSString *text);
@property (nonatomic, copy, nullable) void (^onToggleListening)(void);
@property (nonatomic, copy, nullable) void (^onOpenSettings)(void);
@property (nonatomic, copy, nullable) void (^onOpenCinema)(void);
@property (nonatomic, copy, nullable) void (^onOpen3D)(void);
@property (nonatomic, copy, nullable) void (^onOpenHelp)(void);
@property (nonatomic, copy, nullable) void (^onStop)(void);
@property (nonatomic, copy, nullable) void (^onScenarioChanged)(NSString *identifier);
@property (nonatomic, copy, nullable) void (^onDiagnostics)(void);

- (instancetype)initWithConfiguration:(HALConfiguration *)configuration
                           simulator:(HALShipSimulator *)simulator;

- (void)refreshAppearance;
- (void)refreshSimulator;
- (void)setEyeState:(HALEyeState)state;
- (void)setStatusText:(NSString *)text;
- (void)setListening:(BOOL)listening preview:(nullable NSString *)preview;
- (void)appendMessage:(HALMessage *)message;
- (void)appendMessages:(NSArray<HALMessage *> *)messages;
- (void)beginStreamingReply;
- (void)updateStreamingReply:(NSString *)text;
- (void)finishStreamingReply:(HALMessage *)message;
- (void)cancelStreamingReply;
- (void)clearTranscript;
- (void)toggleSidebar;
- (void)setSidebarVisible:(BOOL)visible;
- (void)setCompactMode:(BOOL)compact;
- (void)focusInput;

@end

NS_ASSUME_NONNULL_END
