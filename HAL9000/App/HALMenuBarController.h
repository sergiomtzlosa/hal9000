#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface HALMenuBarController : NSObject

@property (nonatomic, copy, nullable) void (^onShowHAL)(void);
@property (nonatomic, copy, nullable) void (^onListen)(void);
@property (nonatomic, copy, nullable) void (^onStopSpeaking)(void);
@property (nonatomic, copy, nullable) void (^onMute)(void);
@property (nonatomic, copy, nullable) void (^onSettings)(void);
@property (nonatomic, copy, nullable) void (^onOpen3D)(void);
@property (nonatomic, copy, nullable) void (^onHelp)(void);
@property (nonatomic, copy, nullable) void (^onAbout)(void);
@property (nonatomic, copy, nullable) void (^onQuit)(void);

- (void)setVisible:(BOOL)visible;
- (void)updateListening:(BOOL)listening muted:(BOOL)muted;

@end

NS_ASSUME_NONNULL_END
