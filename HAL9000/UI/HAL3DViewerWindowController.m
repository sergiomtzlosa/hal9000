#import "HAL3DViewerWindowController.h"
#import "HALConfiguration.h"
#import "HALTheme.h"
#import "HALHAL9000Scene.h"
#import "HALDeactivationRoomScene.h"
#import <SceneKit/SceneKit.h>

// The deactivation room is a fixed camera view: no drag-to-orbit and no pan.
// It still needs scroll/pinch zoom, so the view consumes those events itself
// instead of enabling SceneKit's full camera controller for that scene.
@interface HAL3DSceneView : SCNView
@property (nonatomic, assign) BOOL roomZoomEnabled;
@property (nonatomic, copy) void (^zoomHandler)(CGFloat delta);
@end

@implementation HAL3DSceneView

- (void)scrollWheel:(NSEvent *)event {
    if (!self.roomZoomEnabled) {
        [super scrollWheel:event];
        return;
    }
    CGFloat delta = event.hasPreciseScrollingDeltas ? event.scrollingDeltaY : event.deltaY * 5.0;
    if (delta != 0.0 && self.zoomHandler) {
        self.zoomHandler(delta);
    }
}

- (void)magnifyWithEvent:(NSEvent *)event {
    if (!self.roomZoomEnabled) {
        [super magnifyWithEvent:event];
        return;
    }
    if (self.zoomHandler) {
        self.zoomHandler(event.magnification * 100.0);
    }
}

@end

@interface HAL3DViewerWindowController () <NSWindowDelegate>
@property (nonatomic, strong) HALConfiguration *configuration;
@property (nonatomic, strong) HAL3DSceneView *sceneView;
@property (nonatomic, strong) HALHAL9000Scene *halScene;
@property (nonatomic, strong) HALDeactivationRoomScene *roomScene;
@property (nonatomic, strong) NSSegmentedControl *sceneSelector;
@property (nonatomic, strong) NSPopUpButton *cameraPresetPopup;
@property (nonatomic, strong) NSButton *autoRotateCheckbox;
@property (nonatomic, strong) NSButton *deactivateButton;
@property (nonatomic, strong) NSTextField *statusLabel;
@property (nonatomic, assign) BOOL showingRoom;
@property (nonatomic, assign) BOOL deactivating;
@end

@implementation HAL3DViewerWindowController

- (instancetype)initWithConfiguration:(HALConfiguration *)configuration {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 1000, 720)
                                                   styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable)
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    window.title = @"HAL 9000 — 3D Records";
    window.backgroundColor = [NSColor blackColor];
    window.minSize = NSMakeSize(760, 540);
    window.delegate = self;
    self = [super initWithWindow:window];
    if (self) {
        _configuration = configuration;
        [self observeWindowVisibility:window];
        [self buildInterface];
    }
    return self;
}

- (void)observeWindowVisibility:(NSWindow *)window {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(viewerWindowVisibilityChanged:) name:NSWindowDidBecomeKeyNotification object:window];
    [center addObserver:self selector:@selector(viewerWindowVisibilityChanged:) name:NSWindowDidResignKeyNotification object:window];
    [center addObserver:self selector:@selector(viewerWindowVisibilityChanged:) name:NSWindowDidMiniaturizeNotification object:window];
    [center addObserver:self selector:@selector(viewerWindowVisibilityChanged:) name:NSWindowDidDeminiaturizeNotification object:window];
    [center addObserver:self selector:@selector(viewerWindowVisibilityChanged:) name:NSWindowDidChangeOcclusionStateNotification object:window];
    [center addObserver:self selector:@selector(viewerWindowVisibilityChanged:) name:NSApplicationDidBecomeActiveNotification object:nil];
    [center addObserver:self selector:@selector(viewerWindowVisibilityChanged:) name:NSApplicationDidResignActiveNotification object:nil];
}

- (void)viewerWindowVisibilityChanged:(NSNotification *)notification {
    NSWindow *window = self.window;
    BOOL visible = window.isVisible && !window.isMiniaturized && NSApp.isActive &&
                   (window.occlusionState & NSWindowOcclusionStateVisible) != 0;
    // Stop SceneKit's display loop when the viewer is closed, hidden, covered,
    // or the app is in the background. Leaving a 60 fps 3D scene running
    // behind the control room is the main cause of the app feeling sluggish
    // after the viewer has been used.
    self.sceneView.playing = visible;
    if (visible) [self.sceneView setNeedsDisplay:YES];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)buildInterface {
    NSView *content = self.window.contentView;
    content.wantsLayer = YES;
    content.layer.backgroundColor = [NSColor blackColor].CGColor;

    self.sceneView = [[HAL3DSceneView alloc] initWithFrame:NSZeroRect];
    self.sceneView.translatesAutoresizingMaskIntoConstraints = NO;
    self.sceneView.backgroundColor = [NSColor blackColor];
    self.sceneView.autoenablesDefaultLighting = NO;
    self.sceneView.allowsCameraControl = YES;
    self.sceneView.jitteringEnabled = YES;
    // 30 fps keeps orbit and aperture motion smooth while halving the
    // continuous GPU/CPU cost of the two procedural scenes.
    self.sceneView.preferredFramesPerSecond = 30;
    self.sceneView.antialiasingMode = [self.configuration.viewerQuality isEqualToString:@"medium"]
        ? SCNAntialiasingModeMultisampling2X : SCNAntialiasingModeMultisampling4X;
    [content addSubview:self.sceneView];

    NSView *topBar = [[NSView alloc] initWithFrame:NSZeroRect];
    topBar.translatesAutoresizingMaskIntoConstraints = NO;
    topBar.wantsLayer = YES;
    topBar.layer.backgroundColor = [[NSColor colorWithWhite:0.02 alpha:0.80] CGColor];
    topBar.layer.borderColor = [HALTheme line].CGColor;
    topBar.layer.borderWidth = 1.0;
    [content addSubview:topBar];

    NSTextField *title = [NSTextField labelWithString:@"3D RECORDS"];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.font = [HALTheme monoFontOfSize:10 weight:NSFontWeightSemibold];
    title.textColor = [HALTheme halRed];
    [topBar addSubview:title];

    self.sceneSelector = [[NSSegmentedControl alloc] initWithFrame:NSZeroRect];
    self.sceneSelector.translatesAutoresizingMaskIntoConstraints = NO;
    self.sceneSelector.segmentCount = 2;
    [self.sceneSelector setLabel:@"HAL 9000" forSegment:0];
    [self.sceneSelector setLabel:@"DEACTIVATION ROOM" forSegment:1];
    self.sceneSelector.trackingMode = NSSegmentSwitchTrackingSelectOne;
    self.sceneSelector.target = self;
    self.sceneSelector.action = @selector(sceneSelectorChanged:);
    self.sceneSelector.selectedSegment = 0;
    self.sceneSelector.segmentStyle = NSSegmentStyleTexturedRounded;
    self.sceneSelector.font = [HALTheme monoFontOfSize:9 weight:NSFontWeightMedium];
    [topBar addSubview:self.sceneSelector];

    self.cameraPresetPopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    self.cameraPresetPopup.translatesAutoresizingMaskIntoConstraints = NO;
    self.cameraPresetPopup.target = self;
    self.cameraPresetPopup.action = @selector(cameraPresetChanged:);
    self.cameraPresetPopup.font = [HALTheme uiFontOfSize:11 weight:NSFontWeightRegular];
    [topBar addSubview:self.cameraPresetPopup];

    self.autoRotateCheckbox = [NSButton checkboxWithTitle:@"AUTO-ROTATE" target:self action:@selector(autoRotateChanged:)];
    self.autoRotateCheckbox.translatesAutoresizingMaskIntoConstraints = NO;
    self.autoRotateCheckbox.font = [HALTheme monoFontOfSize:9 weight:NSFontWeightMedium];
    self.autoRotateCheckbox.contentTintColor = [HALTheme secondaryText];
    self.autoRotateCheckbox.state = self.configuration.viewerAutoRotate ? NSControlStateValueOn : NSControlStateValueOff;
    [topBar addSubview:self.autoRotateCheckbox];

    self.deactivateButton = [self barButton:@"DEACTIVATE" action:@selector(deactivatePressed:) accent:[HALTheme halRed]];
    [topBar addSubview:self.deactivateButton];

    NSButton *reset = [self barButton:@"RESET VIEW" action:@selector(resetPressed:) accent:[HALTheme secondaryText]];
    [topBar addSubview:reset];

    NSView *bottomBar = [[NSView alloc] initWithFrame:NSZeroRect];
    bottomBar.translatesAutoresizingMaskIntoConstraints = NO;
    bottomBar.wantsLayer = YES;
    bottomBar.layer.backgroundColor = [[NSColor colorWithWhite:0.02 alpha:0.88] CGColor];
    bottomBar.layer.borderColor = [HALTheme line].CGColor;
    bottomBar.layer.borderWidth = 1.0;
    [content addSubview:bottomBar];

    self.statusLabel = [NSTextField labelWithString:@"DRAG TO ORBIT · SCROLL TO ZOOM · OPTION-DRAG TO PAN"];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.font = [HALTheme monoFontOfSize:9 weight:NSFontWeightRegular];
    self.statusLabel.textColor = [HALTheme secondaryText];
    [bottomBar addSubview:self.statusLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.sceneView.topAnchor constraintEqualToAnchor:content.topAnchor],
        [self.sceneView.leadingAnchor constraintEqualToAnchor:content.leadingAnchor],
        [self.sceneView.trailingAnchor constraintEqualToAnchor:content.trailingAnchor],
        [self.sceneView.bottomAnchor constraintEqualToAnchor:content.bottomAnchor],

        [topBar.topAnchor constraintEqualToAnchor:content.topAnchor],
        [topBar.leadingAnchor constraintEqualToAnchor:content.leadingAnchor],
        [topBar.trailingAnchor constraintEqualToAnchor:content.trailingAnchor],
        [topBar.heightAnchor constraintEqualToConstant:52],

        [title.leadingAnchor constraintEqualToAnchor:topBar.leadingAnchor constant:18],
        [title.centerYAnchor constraintEqualToAnchor:topBar.centerYAnchor],

        [self.sceneSelector.leadingAnchor constraintEqualToAnchor:title.trailingAnchor constant:22],
        [self.sceneSelector.centerYAnchor constraintEqualToAnchor:topBar.centerYAnchor],
        [self.sceneSelector.widthAnchor constraintEqualToConstant:260],

        [self.cameraPresetPopup.leadingAnchor constraintEqualToAnchor:self.sceneSelector.trailingAnchor constant:12],
        [self.cameraPresetPopup.centerYAnchor constraintEqualToAnchor:topBar.centerYAnchor],
        [self.cameraPresetPopup.widthAnchor constraintEqualToConstant:150],

        [self.autoRotateCheckbox.leadingAnchor constraintEqualToAnchor:self.cameraPresetPopup.trailingAnchor constant:12],
        [self.autoRotateCheckbox.centerYAnchor constraintEqualToAnchor:topBar.centerYAnchor],

        [self.deactivateButton.trailingAnchor constraintEqualToAnchor:topBar.trailingAnchor constant:-14],
        [self.deactivateButton.centerYAnchor constraintEqualToAnchor:topBar.centerYAnchor],
        [reset.trailingAnchor constraintEqualToAnchor:self.deactivateButton.leadingAnchor constant:-6],
        [reset.centerYAnchor constraintEqualToAnchor:topBar.centerYAnchor],

        [bottomBar.leadingAnchor constraintEqualToAnchor:content.leadingAnchor],
        [bottomBar.trailingAnchor constraintEqualToAnchor:content.trailingAnchor],
        [bottomBar.bottomAnchor constraintEqualToAnchor:content.bottomAnchor],
        [bottomBar.heightAnchor constraintEqualToConstant:30],

        [self.statusLabel.leadingAnchor constraintEqualToAnchor:bottomBar.leadingAnchor constant:18],
        [self.statusLabel.centerYAnchor constraintEqualToAnchor:bottomBar.centerYAnchor]
    ]];

    self.halScene = [[HALHAL9000Scene alloc] initWithQuality:self.configuration.viewerQuality];
    self.halScene.autoRotate = self.configuration.viewerAutoRotate;
    self.roomScene = [[HALDeactivationRoomScene alloc] initWithQuality:self.configuration.viewerQuality];
    self.roomScene.deactivationSpeed = self.configuration.viewerDeactivationSpeed;

    __weak typeof(self) weakSelf = self;
    self.sceneView.zoomHandler = ^(CGFloat delta) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || !self.showingRoom) return;
        [self.roomScene zoomBy:delta];
    };

    [self showHALScene];
}

- (NSButton *)barButton:(NSString *)title action:(SEL)action accent:(NSColor *)accent {
    NSButton *button = [[NSButton alloc] initWithFrame:NSZeroRect];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.bordered = NO;
    button.target = self;
    button.action = action;
    button.wantsLayer = YES;
    button.layer.cornerRadius = 4.0;
    button.layer.backgroundColor = [accent colorWithAlphaComponent:0.10].CGColor;
    button.layer.borderColor = [accent colorWithAlphaComponent:0.35].CGColor;
    button.layer.borderWidth = 1.0;
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment = NSTextAlignmentCenter;
    button.attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:@{
        NSFontAttributeName: [HALTheme monoFontOfSize:8 weight:NSFontWeightSemibold],
        NSForegroundColorAttributeName: accent,
        NSParagraphStyleAttributeName: paragraph
    }];
    [button.heightAnchor constraintEqualToConstant:24].active = YES;
    return button;
}

- (void)showHALScene {
    // Leaving the room cancels any in-flight deactivation. The room no longer
    // offers a RESTORE control, so the reset happens automatically and the next
    // visit always starts with every node and light online.
    self.deactivating = NO;
    if (self.showingRoom && self.roomScene.isDeactivated) {
        [self.roomScene restore];
    }
    self.showingRoom = NO;
    self.sceneView.scene = self.halScene.scene;
    self.sceneView.pointOfView = self.halScene.cameraNode;
    self.halScene.autoRotate = self.autoRotateCheckbox.state == NSControlStateValueOn;
    [self configureCameraControlForRoom:NO];
    [self applyCameraPreset:@"Three-quarter"];
    [self updatePresetMenuForRoom:NO];
    self.autoRotateCheckbox.hidden = NO;
    self.deactivateButton.hidden = YES;
    self.statusLabel.stringValue = @"HAL 9000 · DRAG TO ORBIT · SCROLL TO ZOOM";
}

- (void)showRoomScene {
    self.showingRoom = YES;
    self.sceneView.scene = self.roomScene.scene;
    self.sceneView.pointOfView = self.roomScene.cameraNode;
    [self.halScene setAutoRotate:NO];
    [self configureCameraControlForRoom:YES];
    [self applyCameraPreset:@"Room Wide"];
    [self updatePresetMenuForRoom:YES];
    self.autoRotateCheckbox.hidden = YES;
    self.deactivateButton.hidden = NO;
    self.deactivateButton.enabled = YES;
    self.statusLabel.stringValue = @"DEACTIVATION ROOM · SCROLL TO ZOOM · ORBIT LOCKED";
}

- (void)configureCameraControlForRoom:(BOOL)room {
    SCNCameraController *controller = self.sceneView.defaultCameraController;
    [controller stopInertia];
    // The deactivation room is a fixed presentation view. Disabling camera
    // control prevents drag-to-orbit and also stops SceneKit from swapping
    // in its own free-view camera, so the room can never spin. HAL keeps
    // interactive orbit, zoom, pan, and inertial movement.
    controller.inertiaEnabled = !room;
    self.sceneView.allowsCameraControl = !room;
    self.sceneView.roomZoomEnabled = room;
}

- (void)applyCameraPreset:(NSString *)preset {
    // Once the user drags in an SCNView with allowsCameraControl enabled,
    // SceneKit swaps the point of view for its own free-view camera node.
    // The scene's camera node is then unused, so presets and RESET VIEW
    // would silently do nothing. Reattach the scene camera first, then move
    // it and keep the camera controller's orbit target in sync.
    SCNCameraController *controller = self.sceneView.defaultCameraController;
    [controller stopInertia];
    if (self.showingRoom) {
        self.sceneView.pointOfView = self.roomScene.cameraNode;
        [self.roomScene applyCameraPreset:preset];
        controller.target = [self.roomScene cameraTargetPosition];
    } else {
        self.sceneView.pointOfView = self.halScene.cameraNode;
        [self.halScene applyCameraPreset:preset];
        controller.target = [self.halScene cameraTargetPosition];
    }
    [self.sceneView setNeedsDisplay:YES];
}

- (void)updatePresetMenuForRoom:(BOOL)room {
    [self.cameraPresetPopup removeAllItems];
    NSArray *presets = room ? @[@"Room Wide", @"Console", @"Memory Rack", @"HAL Eye"] : @[@"Eye Detail", @"Three-quarter", @"Wide"];
    for (NSString *preset in presets) {
        [self.cameraPresetPopup addItemWithTitle:preset];
    }
    [self.cameraPresetPopup selectItemAtIndex:room ? 0 : 1];
}

- (void)sceneSelectorChanged:(NSSegmentedControl *)sender {
    if (sender.selectedSegment == 0) [self showHALScene]; else [self showRoomScene];
}

- (void)cameraPresetChanged:(NSPopUpButton *)sender {
    NSString *preset = sender.titleOfSelectedItem;
    if (preset.length == 0) return;
    [self applyCameraPreset:preset];
}

- (void)autoRotateChanged:(NSButton *)sender {
    // Auto-rotation belongs to the HAL eye display only. The deactivation
    // room is always a still camera view with zoom as its only camera gesture.
    if (self.showingRoom) {
        self.halScene.autoRotate = NO;
        return;
    }
    BOOL enabled = sender.state == NSControlStateValueOn;
    self.halScene.autoRotate = enabled;
    self.configuration.viewerAutoRotate = enabled;
}

- (void)resetPressed:(id)sender {
    [self applyCameraPreset:self.showingRoom ? @"Room Wide" : @"Reset"];
}

- (void)deactivatePressed:(id)sender {
    if (self.deactivating) return;
    self.deactivating = YES;
    self.deactivateButton.enabled = NO;
    __weak typeof(self) weakSelf = self;
    [self.roomScene deactivateWithProgress:^(double progress, NSString *subtitle) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.statusLabel.stringValue = [NSString stringWithFormat:@"%3.0f%% · %@", progress * 100.0, subtitle ?: @""];
    } completion:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.deactivating = NO;
        self.statusLabel.stringValue = @"HAL 9000 OFFLINE · THE LOGIC MEMORY CENTER IS DARK";
    }];
}

- (void)refreshConfiguration {
    self.sceneView.antialiasingMode = [self.configuration.viewerQuality isEqualToString:@"medium"]
        ? SCNAntialiasingModeMultisampling2X : SCNAntialiasingModeMultisampling4X;
    self.roomScene.deactivationSpeed = self.configuration.viewerDeactivationSpeed;
    self.autoRotateCheckbox.state = self.configuration.viewerAutoRotate ? NSControlStateValueOn : NSControlStateValueOff;
    self.halScene.autoRotate = self.showingRoom ? NO : self.configuration.viewerAutoRotate;
    [self configureCameraControlForRoom:self.showingRoom];
}

- (void)windowWillClose:(NSNotification *)notification {
    self.sceneView.playing = NO;
    [self.halScene setAutoRotate:NO];
    [self.roomScene restore];
}

@end
