#import "HALHotKeyManager.h"
#import <Carbon/Carbon.h>

static OSStatus HALHotKeyHandler(EventHandlerCallRef nextHandler, EventRef event, void *userData) {
    HALHotKeyManager *manager = (__bridge HALHotKeyManager *)userData;
    EventHotKeyID hotKeyID;
    OSStatus status = GetEventParameter(event,
                                        kEventParamDirectObject,
                                        typeEventHotKeyID,
                                        NULL,
                                        sizeof(hotKeyID),
                                        NULL,
                                        &hotKeyID);
    if (status == noErr && hotKeyID.signature == 0x48414C39 && hotKeyID.id == 1) {
        if (manager.onHotKey) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (manager.onHotKey) manager.onHotKey();
            });
        }
    }
    return noErr;
}

@interface HALHotKeyManager ()
@property (nonatomic, assign) EventHandlerRef eventHandler;
@property (nonatomic, assign) EventHotKeyRef hotKey;
@property (nonatomic, assign) BOOL registered;
@end

@implementation HALHotKeyManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _eventHandler = NULL;
        _hotKey = NULL;
    }
    return self;
}

- (BOOL)registerHotKey {
    if (self.registered) return YES;

    EventTypeSpec eventType;
    eventType.eventClass = kEventClassKeyboard;
    eventType.eventKind = kEventHotKeyPressed;

    OSStatus status = InstallEventHandler(GetApplicationEventTarget(),
                                          HALHotKeyHandler,
                                          1,
                                          &eventType,
                                          (__bridge void *)self,
                                          &_eventHandler);
    if (status != noErr) {
        NSLog(@"HAL hotkey: could not install event handler (%d)", (int)status);
        return NO;
    }

    EventHotKeyID hotKeyID;
    hotKeyID.signature = 0x48414C39; // 'HAL9'
    hotKeyID.id = 1;
    status = RegisterEventHotKey(kVK_Space,
                                 optionKey,
                                 hotKeyID,
                                 GetApplicationEventTarget(),
                                 0,
                                 &_hotKey);
    if (status != noErr) {
        NSLog(@"HAL hotkey: could not register Option-Space (%d)", (int)status);
        RemoveEventHandler(_eventHandler);
        _eventHandler = NULL;
        return NO;
    }

    self.registered = YES;
    return YES;
}

- (void)unregisterHotKey {
    if (self.hotKey) {
        UnregisterEventHotKey(self.hotKey);
        self.hotKey = NULL;
    }
    if (self.eventHandler) {
        RemoveEventHandler(self.eventHandler);
        self.eventHandler = NULL;
    }
    self.registered = NO;
}

- (void)dealloc {
    [self unregisterHotKey];
}

@end
