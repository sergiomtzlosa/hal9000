#import "HALHAL9000Scene.h"
#import "HALTheme.h"

@interface HALHAL9000Scene ()
@property (nonatomic, strong, readwrite) SCNScene *scene;
@property (nonatomic, strong, readwrite) SCNNode *cameraNode;
@property (nonatomic, strong) SCNNode *eyeGroup;
@property (nonatomic, strong) SCNNode *apertureGroup;
@property (nonatomic, strong) SCNNode *targetNode;
@property (nonatomic, assign) BOOL highQuality;
@end

@implementation HALHAL9000Scene

- (instancetype)initWithQuality:(NSString *)quality {
    self = [super init];
    if (self) {
        _highQuality = ![quality isEqualToString:@"medium"];
        [self buildScene];
    }
    return self;
}

- (SCNMaterial *)metalMaterial {
    SCNMaterial *material = [SCNMaterial material];
    material.lightingModelName = SCNLightingModelPhysicallyBased;
    material.diffuse.contents = [HALTheme colorFromHex:@"#202326"];
    material.metalness.contents = @0.92;
    material.roughness.contents = @0.28;
    return material;
}

- (SCNMaterial *)darkMaterial {
    SCNMaterial *material = [SCNMaterial material];
    material.lightingModelName = SCNLightingModelPhysicallyBased;
    material.diffuse.contents = [HALTheme colorFromHex:@"#08090A"];
    material.metalness.contents = @0.75;
    material.roughness.contents = @0.45;
    return material;
}

- (SCNMaterial *)redGlassMaterial {
    SCNMaterial *material = [SCNMaterial material];
    material.lightingModelName = SCNLightingModelPhysicallyBased;
    material.diffuse.contents = [HALTheme colorFromHex:@"#6B0B06"];
    material.emission.contents = [HALTheme colorFromHex:@"#9C120A"];
    material.metalness.contents = @0.25;
    material.roughness.contents = @0.12;
    material.transparency = 0.88;
    material.blendMode = SCNBlendModeAlpha;
    material.doubleSided = YES;
    return material;
}

- (SCNNode *)torusWithRadius:(CGFloat)radius pipe:(CGFloat)pipe material:(SCNMaterial *)material z:(CGFloat)z {
    SCNTorus *torus = [SCNTorus torusWithRingRadius:radius pipeRadius:pipe];
    torus.ringSegmentCount = 96;
    torus.pipeSegmentCount = 24;
    torus.materials = @[material];
    SCNNode *node = [SCNNode nodeWithGeometry:torus];
    node.eulerAngles = SCNVector3Make(M_PI_2, 0, 0);
    node.position = SCNVector3Make(0, 0, z);
    return node;
}

- (SCNNode *)lightNodeWithType:(SCNLightType)type color:(NSColor *)color intensity:(CGFloat)intensity position:(SCNVector3)position {
    SCNLight *light = [SCNLight light];
    light.type = type;
    light.color = color;
    light.intensity = intensity;
    light.castsShadow = NO;
    SCNNode *node = [SCNNode node];
    node.light = light;
    node.position = position;
    return node;
}

- (void)buildScene {
    self.scene = [SCNScene scene];
    self.scene.background.contents = [NSColor blackColor];

    SCNNode *eyeGroup = [SCNNode node];
    eyeGroup.name = @"eyeGroup";
    self.eyeGroup = eyeGroup;
    [self.scene.rootNode addChildNode:eyeGroup];

    // Back housing.
    SCNCylinder *back = [SCNCylinder cylinderWithRadius:3.65 height:1.9];
    back.radialSegmentCount = 96;
    back.materials = @[[self darkMaterial]];
    SCNNode *backNode = [SCNNode nodeWithGeometry:back];
    backNode.eulerAngles = SCNVector3Make(M_PI_2, 0, 0);
    backNode.position = SCNVector3Make(0, 0, -1.15);
    [eyeGroup addChildNode:backNode];

    SCNTube *housingTube = [SCNTube tubeWithInnerRadius:3.05 outerRadius:3.72 height:1.2];
    housingTube.radialSegmentCount = 96;
    housingTube.materials = @[[self metalMaterial]];
    SCNNode *housing = [SCNNode nodeWithGeometry:housingTube];
    housing.eulerAngles = SCNVector3Make(M_PI_2, 0, 0);
    housing.position = SCNVector3Make(0, 0, 0.18);
    [eyeGroup addChildNode:housing];

    [eyeGroup addChildNode:[self torusWithRadius:3.12 pipe:0.28 material:[self metalMaterial] z:0.72]];
    [eyeGroup addChildNode:[self torusWithRadius:3.35 pipe:0.10 material:[self metalMaterial] z:0.98]];
    [eyeGroup addChildNode:[self torusWithRadius:2.91 pipe:0.13 material:[self darkMaterial] z:0.82]];
    [eyeGroup addChildNode:[self torusWithRadius:2.64 pipe:0.05 material:[self metalMaterial] z:0.88]];

    // Lens dome.
    SCNSphere *lensSphere = [SCNSphere sphereWithRadius:2.45];
    lensSphere.segmentCount = 96;
    lensSphere.materials = @[[self redGlassMaterial]];
    SCNNode *lens = [SCNNode nodeWithGeometry:lensSphere];
    lens.scale = SCNVector3Make(1.0, 1.0, 0.58);
    lens.position = SCNVector3Make(0, 0, 0.43);
    [eyeGroup addChildNode:lens];

    // Fine iris rings.
    for (NSInteger i = 0; i < 5; i++) {
        CGFloat radius = 2.24 - (CGFloat)i * 0.36;
        SCNMaterial *mat = [self metalMaterial];
        mat.emission.contents = [[HALTheme halRed] colorWithAlphaComponent:0.22 - (CGFloat)i * 0.025];
        [eyeGroup addChildNode:[self torusWithRadius:radius pipe:0.018 + 0.004 * i material:mat z:0.92]];
    }

    // Mechanical aperture blades.
    SCNNode *aperture = [SCNNode node];
    aperture.name = @"apertureGroup";
    aperture.position = SCNVector3Make(0, 0, 1.02);
    self.apertureGroup = aperture;
    [eyeGroup addChildNode:aperture];

    NSInteger bladeCount = 12;
    for (NSInteger i = 0; i < bladeCount; i++) {
        SCNBox *blade = [SCNBox boxWithWidth:1.92 height:0.48 length:0.07 chamferRadius:0.025];
        blade.materials = @[[self darkMaterial]];
        SCNNode *bladeNode = [SCNNode nodeWithGeometry:blade];
        CGFloat angle = (2.0 * M_PI * i) / bladeCount + 0.18;
        CGFloat radius = 1.38;
        bladeNode.position = SCNVector3Make(cos(angle) * radius, sin(angle) * radius, 0);
        bladeNode.eulerAngles = SCNVector3Make(0, 0, angle + 0.20);
        [aperture addChildNode:bladeNode];
    }

    // Bright pupil and inner glow.
    SCNMaterial *glowMaterial = [SCNMaterial material];
    glowMaterial.lightingModelName = SCNLightingModelConstant;
    glowMaterial.diffuse.contents = [NSColor colorWithSRGBRed:1.0 green:0.20 blue:0.10 alpha:0.52];
    glowMaterial.emission.contents = [NSColor colorWithSRGBRed:1.0 green:0.16 blue:0.06 alpha:0.65];
    glowMaterial.transparency = 0.5;
    glowMaterial.blendMode = SCNBlendModeAdd;
    SCNSphere *glowSphere = [SCNSphere sphereWithRadius:1.12];
    glowSphere.segmentCount = 48;
    glowSphere.materials = @[glowMaterial];
    SCNNode *glow = [SCNNode nodeWithGeometry:glowSphere];
    glow.position = SCNVector3Make(0, 0, 1.12);
    glow.scale = SCNVector3Make(1.0, 1.0, 0.25);
    [eyeGroup addChildNode:glow];

    SCNMaterial *pupilMaterial = [SCNMaterial material];
    pupilMaterial.lightingModelName = SCNLightingModelConstant;
    pupilMaterial.diffuse.contents = [NSColor colorWithSRGBRed:1.0 green:0.94 blue:0.83 alpha:1.0];
    pupilMaterial.emission.contents = [NSColor colorWithSRGBRed:1.0 green:0.62 blue:0.35 alpha:1.0];
    SCNSphere *pupilSphere = [SCNSphere sphereWithRadius:0.30];
    pupilSphere.segmentCount = 48;
    pupilSphere.materials = @[pupilMaterial];
    SCNNode *pupil = [SCNNode nodeWithGeometry:pupilSphere];
    pupil.position = SCNVector3Make(0, 0, 1.58);
    [eyeGroup addChildNode:pupil];

    // Red internal light.
    SCNNode *redLightNode = [self lightNodeWithType:SCNLightTypeOmni
                                               color:[HALTheme halRed]
                                           intensity:760
                                            position:SCNVector3Make(0, 0, 2.2)];
    redLightNode.light.attenuationStartDistance = 1.0;
    redLightNode.light.attenuationEndDistance = 12.0;
    [eyeGroup addChildNode:redLightNode];

    // Pedestal and reflective floor.
    SCNCylinder *pedestal = [SCNCylinder cylinderWithRadius:4.4 height:0.14];
    pedestal.radialSegmentCount = 96;
    SCNMaterial *pedestalMaterial = [self darkMaterial];
    pedestalMaterial.metalness.contents = @0.95;
    pedestalMaterial.roughness.contents = @0.22;
    pedestal.materials = @[pedestalMaterial];
    SCNNode *pedestalNode = [SCNNode nodeWithGeometry:pedestal];
    pedestalNode.position = SCNVector3Make(0, -3.35, 0);
    [self.scene.rootNode addChildNode:pedestalNode];

    SCNFloor *floor = [SCNFloor floor];
    floor.reflectivity = 0.12;
    floor.reflectionFalloffEnd = 12;
    SCNMaterial *floorMaterial = [SCNMaterial material];
    floorMaterial.lightingModelName = SCNLightingModelPhysicallyBased;
    floorMaterial.diffuse.contents = [HALTheme colorFromHex:@"#070809"];
    floorMaterial.roughness.contents = @0.27;
    floorMaterial.metalness.contents = @0.4;
    floor.materials = @[floorMaterial];
    SCNNode *floorNode = [SCNNode nodeWithGeometry:floor];
    floorNode.position = SCNVector3Make(0, -3.43, 0);
    [self.scene.rootNode addChildNode:floorNode];

    // Camera and target.
    SCNNode *target = [SCNNode node];
    target.position = SCNVector3Make(0, 0, 0);
    self.targetNode = target;
    [self.scene.rootNode addChildNode:target];

    SCNCamera *camera = [SCNCamera camera];
    camera.fieldOfView = 38;
    camera.zNear = 0.1;
    camera.zFar = 120;
    camera.wantsHDR = self.highQuality;
    camera.bloomIntensity = self.highQuality ? 0.45 : 0.0;
    camera.bloomThreshold = 0.8;
    camera.bloomBlurRadius = 8;
    SCNNode *cameraNode = [SCNNode node];
    cameraNode.camera = camera;
    cameraNode.position = SCNVector3Make(0, 0, 13);
    [self.scene.rootNode addChildNode:cameraNode];
    SCNLookAtConstraint *lookAt = [SCNLookAtConstraint lookAtConstraintWithTarget:target];
    lookAt.gimbalLockEnabled = YES;
    cameraNode.constraints = @[lookAt];
    self.cameraNode = cameraNode;

    // Studio lights.
    SCNNode *key = [self lightNodeWithType:SCNLightTypeDirectional
                                    color:[NSColor colorWithSRGBRed:1.0 green:0.92 blue:0.84 alpha:1.0]
                                intensity:720
                                 position:SCNVector3Make(-5, 5, 9)];
    key.light.castsShadow = self.highQuality;
    key.light.shadowMode = SCNShadowModeForward;
    key.light.shadowSampleCount = 16;
    key.light.shadowRadius = 6;
    SCNLookAtConstraint *keyLook = [SCNLookAtConstraint lookAtConstraintWithTarget:target];
    key.constraints = @[keyLook];
    [self.scene.rootNode addChildNode:key];

    SCNNode *rim = [self lightNodeWithType:SCNLightTypeDirectional
                                    color:[NSColor colorWithSRGBRed:0.35 green:0.58 blue:0.78 alpha:1.0]
                                intensity:460
                                 position:SCNVector3Make(6, -2, -6)];
    SCNLookAtConstraint *rimLook = [SCNLookAtConstraint lookAtConstraintWithTarget:target];
    rim.constraints = @[rimLook];
    [self.scene.rootNode addChildNode:rim];

    SCNNode *ambient = [self lightNodeWithType:SCNLightTypeAmbient
                                        color:[NSColor colorWithWhite:0.68 alpha:1.0]
                                    intensity:120
                                     position:SCNVector3Zero];
    [self.scene.rootNode addChildNode:ambient];

    [self startIdleAnimation];
}

- (void)startIdleAnimation {
    if (!self.apertureGroup) return;
    [self.apertureGroup removeAllActions];
    SCNAction *rotate = [SCNAction repeatActionForever:[SCNAction rotateByAngle:(M_PI * 2.0) aroundAxis:SCNVector3Make(0, 0, 1) duration:36.0]];
    [self.apertureGroup runAction:rotate];
}

- (void)setAutoRotate:(BOOL)autoRotate {
    _autoRotate = autoRotate;
    if (!self.eyeGroup) return;
    [self.eyeGroup removeAllActions];
    if (autoRotate) {
        SCNAction *rotate = [SCNAction repeatActionForever:[SCNAction rotateByAngle:(M_PI * 2.0) aroundAxis:SCNVector3Make(0, 1, 0) duration:28.0]];
        [self.eyeGroup runAction:rotate];
    }
}

- (void)applyCameraPreset:(NSString *)preset {
    SCNVector3 position = SCNVector3Make(0, 0, 13);
    if ([preset isEqualToString:@"Eye Detail"]) {
        position = SCNVector3Make(0, 0, 7.0);
    } else if ([preset isEqualToString:@"Three-quarter"]) {
        position = SCNVector3Make(5.2, 2.4, 9.2);
    } else if ([preset isEqualToString:@"Wide"]) {
        position = SCNVector3Make(0, 1.0, 18.0);
    }
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:0.55];
    self.cameraNode.position = position;
    [SCNTransaction commit];
}

- (void)resetCamera {
    [self applyCameraPreset:@"Reset"];
}

- (SCNVector3)cameraTargetPosition {
    return self.targetNode.position;
}

@end
