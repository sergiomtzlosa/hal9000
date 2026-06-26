#import "HALLaunchAtLogin.h"
#import <ServiceManagement/ServiceManagement.h>

@implementation HALLaunchAtLogin

+ (instancetype)sharedController {
    static HALLaunchAtLogin *controller;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        controller = [[HALLaunchAtLogin alloc] init];
    });
    return controller;
}

- (BOOL)isEnabled {
    return [SMAppService mainAppService].status == SMAppServiceStatusEnabled;
}

- (BOOL)setEnabled:(BOOL)enabled error:(NSError **)error {
    SMAppService *service = [SMAppService mainAppService];
    SMAppServiceStatus status = service.status;

    if (enabled) {
        if (status == SMAppServiceStatusEnabled) return YES;
        return [service registerAndReturnError:error];
    }

    // A stale "not registered" or "not found" status already means the login
    // item is off. Calling unregisterAndReturnError: in that state can return
    // EPERM on some systems, which previously made the checkbox flip back on
    // and showed a spurious alert.
    if (status == SMAppServiceStatusNotRegistered || status == SMAppServiceStatusNotFound) {
        return YES;
    }
    if ([service unregisterAndReturnError:error]) return YES;

    SMAppServiceStatus afterFailure = service.status;
    return afterFailure == SMAppServiceStatusNotRegistered || afterFailure == SMAppServiceStatusNotFound;
}

@end
