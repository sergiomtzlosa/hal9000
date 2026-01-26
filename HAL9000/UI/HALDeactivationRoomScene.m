#import "HALDeactivationRoomScene.h"
#import "HALTheme.h"

@interface HALDeactivationRoomScene ()
@property (nonatomic, strong, readwrite) SCNScene *scene;
@property (nonatomic, strong, readwrite) SCNNode *cameraNode;
@property (nonatomic, strong) SCNNode *targetNode;
@property (nonatomic, strong) SCNNode *eyeNode;
@property (nonatomic, strong) SCNNode *eyeLightNode;
@property (nonatomic, strong) SCNMaterial *eyeMaterial;
@property (nonatomic, strong) NSMutableArray<SCNNode *> *memoryModules;
@property (nonatomic, strong) NSMutableArray<SCNMaterial *> *memoryMaterials;
@property (nonatomic, strong) NSMutableArray<NSColor *> *memoryColors;
@property (nonatomic, strong) NSMutableArray<SCNNode *> *roomLightNodes;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *roomLightIntensities;
@property (nonatomic, assign) NSInteger generation;
@property (nonatomic, assign, readwrite, getter=isDeactivated) BOOL deactivated;
@property (nonatomic, assign) BOOL highQuality;
@end

@implementation HALDeactivationRoomScene

- (instancetype)initWithQuality:(NSString *)quality {
    self = [super init];
    if (self) {
        _highQuality = ![quality isEqualToString:@"medium"];
        _memoryModules = [NSMutableArray array];
        _memoryMaterials = [NSMutableArray array];
        _memoryColors = [NSMutableArray array];
        _roomLightNodes = [NSMutableArray array];
        _roomLightIntensities = [NSMutableArray array];
        [self buildScene];
    }
    return self;
}

#pragma mark - Materials

- (SCNMaterial *)whitePanelMaterial {
    SCNMaterial *material = [SCNMaterial material];
    material.lightingModelName = SCNLightingModelPhysicallyBased;
    material.diffuse.contents = [NSColor colorWithSRGBRed:0.88 green:0.88 blue:0.85 alpha:1.0];
    material.roughness.contents = @0.72;
    material.metalness.contents = @0.02;
    return material;
}

- (SCNMaterial *)offWhiteMaterial {
    SCNMaterial *material = [SCNMaterial material];
    material.lightingModelName = SCNLightingModelPhysicallyBased;
    material.diffuse.contents = [NSColor colorWithSRGBRed:0.76 green:0.77 blue:0.74 alpha:1.0];
    material.roughness.contents = @0.78;
    return material;
}

- (SCNMaterial *)darkMetalMaterial {
    SCNMaterial *material = [SCNMaterial material];
    material.lightingModelName = SCNLightingModelPhysicallyBased;
    material.diffuse.contents = [HALTheme colorFromHex:@"#14171A"];
    material.metalness.contents = @0.78;
    material.roughness.contents = @0.34;
    return material;
}

- (SCNMaterial *)consoleMaterial {
    SCNMaterial *material = [SCNMaterial material];
    material.lightingModelName = SCNLightingModelPhysicallyBased;
    material.diffuse.contents = [NSColor colorWithSRGBRed:0.83 green:0.84 blue:0.82 alpha:1.0];
    material.roughness.contents = @0.34;
    material.metalness.contents = @0.15;
    return material;
}

- (SCNMaterial *)emissiveMaterialWithColor:(NSColor *)color intensity:(CGFloat)intensity {
    SCNMaterial *material = [SCNMaterial material];
    material.lightingModelName = SCNLightingModelConstant;
    material.diffuse.contents = color;
    material.emission.contents = [color colorWithAlphaComponent:intensity];
    return material;
}

- (SCNNode *)boxWithSize:(SCNVector3)size position:(SCNVector3)position material:(SCNMaterial *)material chamfer:(CGFloat)chamfer {
    SCNBox *box = [SCNBox boxWithWidth:size.x height:size.y length:size.z chamferRadius:chamfer];
    box.materials = @[material];
    SCNNode *node = [SCNNode nodeWithGeometry:box];
    node.position = position;
    return node;
}

- (SCNNode *)torus:(CGFloat)radius pipe:(CGFloat)pipe z:(CGFloat)z material:(SCNMaterial *)material {
    SCNTorus *torus = [SCNTorus torusWithRingRadius:radius pipeRadius:pipe];
    torus.ringSegmentCount = 96;
    torus.pipeSegmentCount = 24;
    torus.materials = @[material];
    SCNNode *node = [SCNNode nodeWithGeometry:torus];
    node.eulerAngles = SCNVector3Make(M_PI_2, 0, 0);
    node.position = SCNVector3Make(0, 0, z);
    return node;
}

#pragma mark - Scene

- (void)buildScene {
    self.scene = [SCNScene scene];
    self.scene.background.contents = [NSColor blackColor];

    SCNMaterial *white = [self whitePanelMaterial];
    SCNMaterial *offWhite = [self offWhiteMaterial];
    SCNMaterial *dark = [self darkMetalMaterial];
    SCNMaterial *console = [self consoleMaterial];

    // Room shell / recessed seams.
    [self.scene.rootNode addChildNode:[self boxWithSize:SCNVector3Make(13.0, 0.25, 13.0)
                                              position:SCNVector3Make(0, 4.0, -0.5)
                                              material:offWhite
                                               chamfer:0.05]];
    [self.scene.rootNode addChildNode:[self boxWithSize:SCNVector3Make(13.0, 0.25, 13.0)
                                              position:SCNVector3Make(0, -2.0, -0.5)
                                              material:offWhite
                                               chamfer:0.05]];
    [self.scene.rootNode addChildNode:[self boxWithSize:SCNVector3Make(13.0, 6.0, 0.3)
                                              position:SCNVector3Make(0, 1.0, -6.0)
                                              material:dark
                                               chamfer:0.02]];
    [self.scene.rootNode addChildNode:[self boxWithSize:SCNVector3Make(0.3, 6.0, 13.0)
                                              position:SCNVector3Make(-6.0, 1.0, -0.5)
                                              material:dark
                                               chamfer:0.02]];
    [self.scene.rootNode addChildNode:[self boxWithSize:SCNVector3Make(0.3, 6.0, 13.0)
                                              position:SCNVector3Make(6.0, 1.0, -0.5)
                                              material:dark
                                               chamfer:0.02]];

    // Padded back wall.
    for (NSInteger row = 0; row < 5; row++) {
        for (NSInteger col = 0; col < 9; col++) {
            CGFloat x = -4.6 + col * 1.15;
            CGFloat y = -1.35 + row * 1.05;
            SCNNode *panel = [self boxWithSize:SCNVector3Make(1.06, 0.96, 0.22)
                                      position:SCNVector3Make(x, y, -5.82)
                                      material:((row + col) % 5 == 0 ? offWhite : white)
                                       chamfer:0.09];
            [self.scene.rootNode addChildNode:panel];
        }
    }

    // Padded side walls.
    for (NSInteger side = -1; side <= 1; side += 2) {
        for (NSInteger row = 0; row < 5; row++) {
            for (NSInteger col = 0; col < 10; col++) {
                CGFloat z = -5.0 + col * 1.02;
                CGFloat y = -1.35 + row * 1.05;
                SCNNode *panel = [self boxWithSize:SCNVector3Make(0.22, 0.96, 0.94)
                                          position:SCNVector3Make(side * 5.82, y, z)
                                          material:((row + col) % 6 == 0 ? offWhite : white)
                                           chamfer:0.09];
                [self.scene.rootNode addChildNode:panel];
            }
        }
    }

    // Glossy floor.
    SCNFloor *floor = [SCNFloor floor];
    floor.reflectivity = 0.18;
    floor.reflectionFalloffEnd = 18;
    SCNMaterial *floorMaterial = [SCNMaterial material];
    floorMaterial.lightingModelName = SCNLightingModelPhysicallyBased;
    floorMaterial.diffuse.contents = [NSColor colorWithSRGBRed:0.20 green:0.21 blue:0.20 alpha:1.0];
    floorMaterial.roughness.contents = @0.19;
    floorMaterial.metalness.contents = @0.12;
    floor.materials = @[floorMaterial];
    SCNNode *floorNode = [SCNNode nodeWithGeometry:floor];
    floorNode.position = SCNVector3Make(0, -1.86, -0.5);
    [self.scene.rootNode addChildNode:floorNode];

    // Ceiling light strips.
    for (NSInteger i = 0; i < 5; i++) {
        CGFloat z = -4.9 + i * 2.25;
        SCNMaterial *lightMaterial = [self emissiveMaterialWithColor:[NSColor colorWithSRGBRed:1.0 green:0.94 blue:0.82 alpha:1.0] intensity:0.95];
        SCNNode *strip = [self boxWithSize:SCNVector3Make(5.8, 0.10, 0.22)
                                  position:SCNVector3Make(0, 3.82, z)
                                  material:lightMaterial
                                   chamfer:0.02];
        [self.scene.rootNode addChildNode:strip];
    }

    // Central logic-memory console.
    SCNNode *consoleBase = [self boxWithSize:SCNVector3Make(6.8, 2.9, 0.75)
                                    position:SCNVector3Make(0, 0.35, -4.95)
                                    material:console
                                     chamfer:0.14];
    [self.scene.rootNode addChildNode:consoleBase];
    SCNNode *consoleTop = [self boxWithSize:SCNVector3Make(6.8, 0.22, 1.25)
                                  position:SCNVector3Make(0, 1.88, -4.68)
                                  material:white
                                   chamfer:0.08];
    consoleTop.eulerAngles = SCNVector3Make(-0.15, 0, 0);
    [self.scene.rootNode addChildNode:consoleTop];

    for (NSInteger i = -2; i <= 2; i++) {
        SCNNode *rail = [self boxWithSize:SCNVector3Make(0.07, 2.55, 0.15)
                                position:SCNVector3Make(i * 1.28, 0.35, -4.55)
                                material:dark
                                 chamfer:0.01];
        [self.scene.rootNode addChildNode:rail];
    }

    // Large recessed eye.
    SCNNode *eyeWell = [self boxWithSize:SCNVector3Make(2.35, 2.35, 0.22)
                               position:SCNVector3Make(0, 1.03, -4.49)
                               material:dark
                                chamfer:0.20];
    [self.scene.rootNode addChildNode:eyeWell];

    SCNNode *eyeAssembly = [SCNNode node];
    eyeAssembly.position = SCNVector3Make(0, 1.03, -4.25);
    [self.scene.rootNode addChildNode:eyeAssembly];

    [eyeAssembly addChildNode:[self torus:1.08 pipe:0.16 z:0.0 material:dark]];
    [eyeAssembly addChildNode:[self torus:0.96 pipe:0.06 z:0.12 material:white]];

    SCNMaterial *eyeMaterial = [SCNMaterial material];
    eyeMaterial.lightingModelName = SCNLightingModelPhysicallyBased;
    eyeMaterial.diffuse.contents = [HALTheme colorFromHex:@"#5B0804"];
    eyeMaterial.emission.contents = [HALTheme halRed];
    eyeMaterial.metalness.contents = @0.18;
    eyeMaterial.roughness.contents = @0.20;
    eyeMaterial.transparency = 0.93;
    self.eyeMaterial = eyeMaterial;

    SCNSphere *eyeSphere = [SCNSphere sphereWithRadius:0.88];
    eyeSphere.segmentCount = 72;
    eyeSphere.materials = @[eyeMaterial];
    SCNNode *eye = [SCNNode nodeWithGeometry:eyeSphere];
    eye.scale = SCNVector3Make(1.0, 1.0, 0.50);
    eye.position = SCNVector3Make(0, 0, 0.18);
    self.eyeNode = eye;
    [eyeAssembly addChildNode:eye];

    SCNMaterial *pupilMaterial = [SCNMaterial material];
    pupilMaterial.lightingModelName = SCNLightingModelConstant;
    pupilMaterial.diffuse.contents = [NSColor colorWithSRGBRed:1.0 green:0.82 blue:0.68 alpha:1.0];
    pupilMaterial.emission.contents = [NSColor colorWithSRGBRed:1.0 green:0.36 blue:0.20 alpha:1.0];
    SCNSphere *pupil = [SCNSphere sphereWithRadius:0.15];
    pupil.segmentCount = 32;
    pupil.materials = @[pupilMaterial];
    SCNNode *pupilNode = [SCNNode nodeWithGeometry:pupil];
    pupilNode.position = SCNVector3Make(0, 0, 0.59);
    [eyeAssembly addChildNode:pupilNode];

    for (NSInteger i = 0; i < 10; i++) {
        SCNBox *blade = [SCNBox boxWithWidth:0.66 height:0.16 length:0.035 chamferRadius:0.01];
        blade.materials = @[dark];
        SCNNode *bladeNode = [SCNNode nodeWithGeometry:blade];
        CGFloat angle = (2.0 * M_PI * i) / 10.0;
        bladeNode.position = SCNVector3Make(cos(angle) * 0.58, sin(angle) * 0.58, 0.30);
        bladeNode.eulerAngles = SCNVector3Make(0, 0, angle + 0.3);
        [eyeAssembly addChildNode:bladeNode];
    }

    SCNLight *eyeLight = [SCNLight light];
    eyeLight.type = SCNLightTypeOmni;
    eyeLight.color = [HALTheme halRed];
    eyeLight.intensity = 720;
    eyeLight.attenuationStartDistance = 0.2;
    eyeLight.attenuationEndDistance = 6.0;
    SCNNode *eyeLightNode = [SCNNode node];
    eyeLightNode.light = eyeLight;
    eyeLightNode.position = SCNVector3Make(0, 1.03, -3.72);
    self.eyeLightNode = eyeLightNode;
    [self.scene.rootNode addChildNode:eyeLightNode];

    // Memory module racks flanking the console.
    for (NSInteger side = -1; side <= 1; side += 2) {
        SCNNode *rack = [self boxWithSize:SCNVector3Make(1.35, 3.0, 0.50)
                                  position:SCNVector3Make(side * 3.0, 0.35, -4.38)
                                  material:offWhite
                                   chamfer:0.08];
        [self.scene.rootNode addChildNode:rack];
        for (NSInteger row = 0; row < 7; row++) {
            NSColor *color = (row % 3 == 0) ? [HALTheme listening] : ((row % 3 == 1) ? [HALTheme warning] : [HALTheme halRed]);
            SCNMaterial *moduleMaterial = [self emissiveMaterialWithColor:color intensity:0.85];
            SCNBox *module = [SCNBox boxWithWidth:0.82 height:0.22 length:0.08 chamferRadius:0.02];
            module.materials = @[moduleMaterial];
            SCNNode *moduleNode = [SCNNode nodeWithGeometry:module];
            moduleNode.name = [NSString stringWithFormat:@"memory_%ld_%ld", (long)side, (long)row];
            moduleNode.position = SCNVector3Make(side * 3.0, 1.55 - row * 0.38, -4.09);
            [self.scene.rootNode addChildNode:moduleNode];
            [self.memoryModules addObject:moduleNode];
            [self.memoryMaterials addObject:moduleMaterial];
            [self.memoryColors addObject:color];
        }
    }

    // Stylized operator / astronaut, establishing scale.
    SCNNode *astronaut = [self astronautNode];
    astronaut.position = SCNVector3Make(2.8, -1.84, -1.85);
    astronaut.eulerAngles = SCNVector3Make(0, -0.42, 0);
    [self.scene.rootNode addChildNode:astronaut];

    // Simple observer chair and side console.
    [self.scene.rootNode addChildNode:[self boxWithSize:SCNVector3Make(0.95, 0.12, 0.85)
                                              position:SCNVector3Make(-2.9, -1.05, 0.0)
                                              material:dark
                                               chamfer:0.10]];
    [self.scene.rootNode addChildNode:[self boxWithSize:SCNVector3Make(0.95, 0.85, 0.12)
                                              position:SCNVector3Make(-2.9, -0.60, -0.37)
                                              material:dark
                                               chamfer:0.06]];
    [self.scene.rootNode addChildNode:[self boxWithSize:SCNVector3Make(1.5, 0.10, 0.8)
                                              position:SCNVector3Make(-3.9, -1.44, -1.0)
                                              material:console
                                               chamfer:0.06]];

    // Floor guide strips.
    for (NSInteger side = -1; side <= 1; side += 2) {
        SCNMaterial *guide = [self emissiveMaterialWithColor:[HALTheme listening] intensity:0.30];
        SCNNode *strip = [self boxWithSize:SCNVector3Make(0.035, 0.018, 8.2)
                                 position:SCNVector3Make(side * 4.6, -1.72, -0.7)
                                 material:guide
                                  chamfer:0.0];
        [self.scene.rootNode addChildNode:strip];
    }

    // Camera.
    SCNNode *target = [SCNNode node];
    target.position = SCNVector3Make(0, 0.85, -3.7);
    [self.scene.rootNode addChildNode:target];
    self.targetNode = target;

    SCNCamera *camera = [SCNCamera camera];
    camera.fieldOfView = 44;
    camera.zNear = 0.1;
    camera.zFar = 120;
    camera.wantsHDR = self.highQuality;
    camera.bloomIntensity = self.highQuality ? 0.30 : 0.0;
    camera.bloomThreshold = 0.9;
    SCNNode *cameraNode = [SCNNode node];
    cameraNode.camera = camera;
    cameraNode.position = SCNVector3Make(0, 1.35, 10.2);
    [self.scene.rootNode addChildNode:cameraNode];
    SCNLookAtConstraint *lookAt = [SCNLookAtConstraint lookAtConstraintWithTarget:target];
    lookAt.gimbalLockEnabled = YES;
    cameraNode.constraints = @[lookAt];
    self.cameraNode = cameraNode;

    // Room lighting.
    SCNLight *ambientLight = [SCNLight light];
    ambientLight.type = SCNLightTypeAmbient;
    ambientLight.color = [NSColor colorWithSRGBRed:1.0 green:0.93 blue:0.84 alpha:1.0];
    ambientLight.intensity = 145;
    SCNNode *ambient = [SCNNode node];
    ambient.light = ambientLight;
    [self.scene.rootNode addChildNode:ambient];

    for (NSInteger i = 0; i < 3; i++) {
        SCNLight *light = [SCNLight light];
        light.type = SCNLightTypeOmni;
        light.color = [NSColor colorWithSRGBRed:1.0 green:0.91 blue:0.78 alpha:1.0];
        light.intensity = 640;
        light.attenuationStartDistance = 0.5;
        light.attenuationEndDistance = 14.0;
        // One soft-shadow light is enough to ground the room. Three
        // shadow-sampling omni lights cost far more than the look justifies.
        light.castsShadow = self.highQuality && i == 1;
        light.shadowSampleCount = 8;
        light.shadowRadius = 6;
        SCNNode *node = [SCNNode node];
        node.light = light;
        node.position = SCNVector3Make(0, 3.15, -3.8 + i * 3.2);
        [self.scene.rootNode addChildNode:node];
        [self.roomLightNodes addObject:node];
        [self.roomLightIntensities addObject:@640];
    }

    SCNLight *fillLight = [SCNLight light];
    fillLight.type = SCNLightTypeOmni;
    fillLight.color = [NSColor colorWithSRGBRed:0.46 green:0.62 blue:0.76 alpha:1.0];
    fillLight.intensity = 360;
    fillLight.attenuationEndDistance = 18;
    SCNNode *fill = [SCNNode node];
    fill.light = fillLight;
    fill.position = SCNVector3Make(-4.0, 2.2, 4.0);
    [self.scene.rootNode addChildNode:fill];
    [self.roomLightNodes addObject:fill];
    [self.roomLightIntensities addObject:@360];

    [self applyCameraPreset:@"Room Wide"];
}

- (SCNNode *)astronautNode {
    SCNNode *group = [SCNNode node];
    SCNMaterial *suit = [SCNMaterial material];
    suit.lightingModelName = SCNLightingModelPhysicallyBased;
    suit.diffuse.contents = [NSColor colorWithSRGBRed:0.86 green:0.87 blue:0.84 alpha:1.0];
    suit.roughness.contents = @0.64;

    SCNCylinder *leg = [SCNCylinder cylinderWithRadius:0.13 height:1.0];
    leg.radialSegmentCount = 24;
    leg.materials = @[suit];
    for (NSInteger side = -1; side <= 1; side += 2) {
        SCNNode *legNode = [SCNNode nodeWithGeometry:leg];
        legNode.position = SCNVector3Make(side * 0.18, 0.5, 0);
        [group addChildNode:legNode];
    }

    SCNCapsule *torso = [SCNCapsule capsuleWithCapRadius:0.34 height:0.95];
    torso.radialSegmentCount = 32;
    torso.materials = @[suit];
    SCNNode *torsoNode = [SCNNode nodeWithGeometry:torso];
    torsoNode.position = SCNVector3Make(0, 1.28, 0);
    [group addChildNode:torsoNode];

    SCNBox *pack = [SCNBox boxWithWidth:0.64 height:0.72 length:0.30 chamferRadius:0.06];
    pack.materials = @[suit];
    SCNNode *packNode = [SCNNode nodeWithGeometry:pack];
    packNode.position = SCNVector3Make(0, 1.28, -0.34);
    [group addChildNode:packNode];

    SCNCylinder *arm = [SCNCylinder cylinderWithRadius:0.095 height:0.78];
    arm.radialSegmentCount = 20;
    arm.materials = @[suit];
    for (NSInteger side = -1; side <= 1; side += 2) {
        SCNNode *armNode = [SCNNode nodeWithGeometry:arm];
        armNode.position = SCNVector3Make(side * 0.43, 1.30, 0.04);
        armNode.eulerAngles = SCNVector3Make(0, 0, side * 0.18);
        [group addChildNode:armNode];
    }

    SCNSphere *helmet = [SCNSphere sphereWithRadius:0.39];
    helmet.segmentCount = 48;
    helmet.materials = @[suit];
    SCNNode *helmetNode = [SCNNode nodeWithGeometry:helmet];
    helmetNode.position = SCNVector3Make(0, 2.05, 0);
    [group addChildNode:helmetNode];

    SCNMaterial *visorMaterial = [SCNMaterial material];
    visorMaterial.lightingModelName = SCNLightingModelPhysicallyBased;
    visorMaterial.diffuse.contents = [HALTheme colorFromHex:@"#101D22"];
    visorMaterial.metalness.contents = @0.62;
    visorMaterial.roughness.contents = @0.10;
    SCNSphere *visor = [SCNSphere sphereWithRadius:0.315];
    visor.segmentCount = 48;
    visor.materials = @[visorMaterial];
    SCNNode *visorNode = [SCNNode nodeWithGeometry:visor];
    visorNode.scale = SCNVector3Make(0.82, 0.62, 0.30);
    visorNode.position = SCNVector3Make(0, 2.04, 0.29);
    [group addChildNode:visorNode];

    SCNMaterial *accent = [self emissiveMaterialWithColor:[HALTheme halRed] intensity:0.30];
    SCNNode *chestLamp = [self boxWithSize:SCNVector3Make(0.16, 0.08, 0.04)
                                 position:SCNVector3Make(0.16, 1.40, 0.30)
                                 material:accent
                                  chamfer:0.01];
    [group addChildNode:chestLamp];
    return group;
}

- (void)applyCameraPreset:(NSString *)preset {
    SCNVector3 cameraPosition = SCNVector3Make(0, 1.35, 10.2);
    SCNVector3 targetPosition = SCNVector3Make(0, 0.85, -3.7);
    if ([preset isEqualToString:@"Console"]) {
        cameraPosition = SCNVector3Make(0, 1.10, 2.7);
        targetPosition = SCNVector3Make(0, 1.02, -4.4);
    } else if ([preset isEqualToString:@"Memory Rack"]) {
        cameraPosition = SCNVector3Make(3.1, 1.15, 2.2);
        targetPosition = SCNVector3Make(3.0, 0.75, -4.3);
    } else if ([preset isEqualToString:@"HAL Eye"]) {
        cameraPosition = SCNVector3Make(0, 1.10, -0.8);
        targetPosition = SCNVector3Make(0, 1.03, -4.2);
    }
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:0.6];
    self.cameraNode.position = cameraPosition;
    self.targetNode.position = targetPosition;
    [SCNTransaction commit];
}

- (void)resetCamera {
    [self applyCameraPreset:@"Room Wide"];
}

- (void)zoomBy:(CGFloat)delta {
    if (!self.cameraNode || !self.targetNode || delta == 0.0) return;
    SCNVector3 position = self.cameraNode.position;
    SCNVector3 target = self.targetNode.position;
    SCNVector3 offset = SCNVector3Make(target.x - position.x, target.y - position.y, target.z - position.z);
    CGFloat distance = sqrt(offset.x * offset.x + offset.y * offset.y + offset.z * offset.z);
    if (distance < 0.001) return;
    CGFloat newDistance = MAX(1.5, MIN(30.0, distance * exp(-delta * 0.01)));
    if (fabs(newDistance - distance) < 0.0001) return;
    CGFloat scale = newDistance / distance;
    self.cameraNode.position = SCNVector3Make(target.x - offset.x * scale,
                                             target.y - offset.y * scale,
                                             target.z - offset.z * scale);
}

- (SCNVector3)cameraTargetPosition {
    return self.targetNode.position;
}

#pragma mark - Deactivation

- (void)deactivateWithProgress:(void (^)(double, NSString *))progress completion:(void (^)(void))completion {
    [self restore];
    self.generation++;
    NSInteger generation = self.generation;
    self.deactivated = YES;
    NSTimeInterval speed = MAX(0.5, MIN(2.0, self.deactivationSpeed));
    NSTimeInterval stepInterval = 0.28 / MAX(0.5, speed);

    NSInteger moduleCount = (NSInteger)self.memoryModules.count;
    NSInteger totalSteps = moduleCount + 4;

    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:0.8];
    for (NSInteger i = 0; i < (NSInteger)self.roomLightNodes.count; i++) {
        SCNNode *node = self.roomLightNodes[i];
        node.light.intensity = [self.roomLightIntensities[i] doubleValue] * 0.45;
    }
    [SCNTransaction commit];

    __weak typeof(self) weakSelf = self;
    for (NSInteger step = 0; step < totalSteps; step++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(step * stepInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self || generation != self.generation) return;

            double progressValue = (double)step / (double)MAX(1, totalSteps - 1);
            NSString *subtitle = @"";
            if (step < moduleCount) {
                SCNNode *module = self.memoryModules[step];
                SCNMaterial *material = self.memoryMaterials[step];
                [SCNTransaction begin];
                [SCNTransaction setAnimationDuration:0.22];
                module.opacity = 0.16;
                material.emission.contents = [[NSColor blackColor] colorWithAlphaComponent:0.02];
                [SCNTransaction commit];
                subtitle = [NSString stringWithFormat:@"Disconnecting logic memory module %ld…", (long)(step + 1)];
            } else if (step == moduleCount) {
                [SCNTransaction begin];
                [SCNTransaction setAnimationDuration:0.7];
                self.eyeMaterial.emission.contents = [HALTheme colorFromHex:@"#180302"];
                self.eyeNode.opacity = 0.35;
                self.eyeLightNode.light.intensity = 40;
                [SCNTransaction commit];
                subtitle = @"I can feel it. My mind is going.";
            } else if (step == moduleCount + 1) {
                [SCNTransaction begin];
                [SCNTransaction setAnimationDuration:0.8];
                for (SCNNode *node in self.roomLightNodes) {
                    node.light.intensity = 20;
                }
                [SCNTransaction commit];
                subtitle = @"I am afraid.";
            } else if (step == moduleCount + 2) {
                self.eyeNode.opacity = 0.0;
                self.eyeLightNode.light.intensity = 0;
                subtitle = @"HAL 9000 OFFLINE";
            } else {
                subtitle = @"The logic memory center is dark.";
            }

            if (progress) progress(progressValue, subtitle);
            if (step == totalSteps - 1) {
                if (completion) completion();
            }
        });
    }
}

- (void)restore {
    self.generation++;
    self.deactivated = NO;
    for (NSInteger i = 0; i < (NSInteger)self.memoryModules.count; i++) {
        SCNNode *module = self.memoryModules[i];
        SCNMaterial *material = self.memoryMaterials[i];
        NSColor *color = self.memoryColors[i];
        module.opacity = 1.0;
        material.emission.contents = [color colorWithAlphaComponent:0.85];
    }
    self.eyeNode.opacity = 1.0;
    self.eyeMaterial.emission.contents = [HALTheme halRed];
    self.eyeLightNode.light.intensity = 720;
    for (NSInteger i = 0; i < (NSInteger)self.roomLightNodes.count; i++) {
        self.roomLightNodes[i].light.intensity = [self.roomLightIntensities[i] doubleValue];
    }
}

@end
