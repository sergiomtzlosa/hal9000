#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HALHAL9000Scene : NSObject

@property (nonatomic, strong, readonly) SCNScene *scene;
@property (nonatomic, strong, readonly) SCNNode *cameraNode;
@property (nonatomic, assign) BOOL autoRotate;

- (instancetype)initWithQuality:(NSString *)quality;
- (void)applyCameraPreset:(NSString *)preset;
- (void)resetCamera;
- (SCNVector3)cameraTargetPosition;

@end

NS_ASSUME_NONNULL_END
