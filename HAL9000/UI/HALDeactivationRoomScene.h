#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HALDeactivationRoomScene : NSObject

@property (nonatomic, strong, readonly) SCNScene *scene;
@property (nonatomic, strong, readonly) SCNNode *cameraNode;
@property (nonatomic, assign, readonly, getter=isDeactivated) BOOL deactivated;
@property (nonatomic, assign) double deactivationSpeed;

- (instancetype)initWithQuality:(NSString *)quality;
- (void)applyCameraPreset:(NSString *)preset;
- (void)resetCamera;
- (void)zoomBy:(CGFloat)delta;
- (SCNVector3)cameraTargetPosition;

- (void)deactivateWithProgress:(void (^ _Nullable)(double progress, NSString *subtitle))progress
                    completion:(void (^ _Nullable)(void))completion;
- (void)restore;

@end

NS_ASSUME_NONNULL_END
