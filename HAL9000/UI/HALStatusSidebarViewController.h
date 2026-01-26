#import <Cocoa/Cocoa.h>
#import "HALCore.h"

NS_ASSUME_NONNULL_BEGIN

@interface HALStatusSidebarViewController : NSViewController

@property (nonatomic, strong) HALShipSimulator *simulator;
@property (nonatomic, strong) HALConfiguration *configuration;
@property (nonatomic, copy, nullable) void (^onScenarioChanged)(NSString *identifier);
@property (nonatomic, copy, nullable) void (^onDiagnostics)(void);
@property (nonatomic, copy, nullable) void (^onOpen3D)(void);

- (void)refresh;

@end

NS_ASSUME_NONNULL_END
