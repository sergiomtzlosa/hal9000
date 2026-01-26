#import <Cocoa/Cocoa.h>
#import "HALEyeView.h"

@class HALConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface HALCinemaWindowController : NSWindowController

@property (nonatomic, copy, nullable) void (^onClose)(void);
@property (nonatomic, copy, nullable) void (^onToggleListening)(void);

- (instancetype)initWithConfiguration:(HALConfiguration *)configuration;
- (void)refreshAppearance;
- (void)setEyeState:(HALEyeState)state;
- (void)setSubtitle:(NSString *)subtitle;
- (void)setStatus:(NSString *)status;
- (void)showCinema;
- (void)closeCinema;

@end

NS_ASSUME_NONNULL_END
