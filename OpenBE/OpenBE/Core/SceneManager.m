/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2018 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "SceneManager.h"
#import "Core.h"

#ifdef ENABLE_COMPONENT_PROFILING
#include <mach/mach.h>
#include <mach/mach_time.h>
#endif

@import GLKit;

@interface SceneManager ()

@property (atomic) NSTimeInterval previousTimeInterval;
@property (nonatomic) BOOL isStereo;

@end

@implementation SceneManager

#pragma mark - Class

+ (SceneManager *) main {
    static SceneManager * mainSceneManager;
    if( mainSceneManager == NULL) {
        mainSceneManager = [[SceneManager alloc] init];
    }
    
    return mainSceneManager;
}

#pragma mark - Getters

- (BEViewRenderingAPI)renderingAPI
{
    return self.mixedRealityMode.beView.renderingAPI;
}

#pragma mark - Init

- (id) init {
    self = [super init];
    
    self.entities = [[NSMutableArray alloc] initWithCapacity:32];
    
    return self;
}

- (void) initWithMixedRealityMode:(BEMixedRealityMode *)mixedRealityMode stereo:(BOOL)stereo {
    self.isStereo = stereo;
    self.mixedRealityMode = mixedRealityMode;
    
    // update scene
    [Scene main].scene = mixedRealityMode.sceneKitScene;
    [Scene main].rootNode = mixedRealityMode.worldNodeWhenRelocalized;
    
    // Get and adjust the lights.
    SCNNode *overheadLightNode = [mixedRealityMode.sceneKitScene.rootNode childNodeWithName:@"OverheadLight" recursively:YES];
    SCNLight *overheadLight = overheadLightNode.light;
    overheadLight.spotOuterAngle = 70; // Wider cone so we don't see a hard fall-off.
    
    SCNNode *ambientLightNode = [mixedRealityMode.sceneKitScene.rootNode childNodeWithName:@"AmbientLight" recursively:YES];
    SCNLight *ambientLight = ambientLightNode.light;
    ambientLight.color = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1];
    
    // Get all the coarseMesh nodes that define the world, and apply our own physics to it.
    SCNNode *rootNode = mixedRealityMode.sceneKitScene.rootNode;
    NSArray<SCNNode*> *coarseMeshNodes = [rootNode childNodesPassingTest:
    ^BOOL(SCNNode * _Nonnull child, BOOL * _Nonnull stop) {
        return child.name != nil && [child.name isEqualToString:@"coarseMesh"];
    }];
  
    for(SCNNode *coarseMesh in coarseMeshNodes ) {
        SCNPhysicsBody *worldBody = coarseMesh.physicsBody;
        worldBody.mass = 100000;  // Super heavy world.
        worldBody.type = SCNPhysicsBodyTypeStatic;
        worldBody.categoryBitMask = BECollisionCategoryRealWorld;
        worldBody.contactTestBitMask = BECollisionCategoryRealWorld;
        worldBody.collisionBitMask = SCNPhysicsCollisionCategoryAll;
        worldBody.friction = 0.5; // Default, some friction.
        worldBody.rollingFriction = 0.1; // Hard surface allows lots of rolling.
        worldBody.restitution = 0.9;  // Lots of bounciness. (hard surfaces)
        worldBody.damping = 0.1; // Default, allow motion due to movement.
        worldBody.angularDamping = 0.1; // Default, allow regular rolling due to movement.
        [worldBody resetTransform];
        [worldBody clearAllForces];
    }

    [self updateSingletons:mixedRealityMode withDeltaTime:0.f];
}

#pragma mark - Components

- (void) addEntity:(GKEntity * ) entity {
    [self.entities addObject:entity];
}

- (void) removeEntity:(GKEntity *)entity {
    [self.entities removeObject:entity];
}

- (GKEntity * ) createEntity {
    GKEntity * entity = [[GKEntity alloc] init];
    [self addEntity:entity];
    return entity;
}

- (GKEntity *) createEntityWithSceneNode:(SCNNode *)node {
    GKEntity * entity = [self createEntity];
    GeometryComponent * component = [[GeometryComponent alloc] initWithNode:node];
    
    [entity addComponent:component];
    
    return entity;
}

- (void) updateSingletons:(BEMixedRealityMode *) mixedRealityMode withDeltaTime:(NSTimeInterval)seconds {
    // update camera
    [[Camera main] updateWithDeltaTime:seconds andNode:mixedRealityMode.localDeviceNode  andCamera:mixedRealityMode.sceneKitCamera];
    
    // event system
    [[EventManager main] updateWithDeltaTime:(NSTimeInterval)seconds];
}


- (void) applyGrippyToPhysicsBody:(SCNPhysicsBody*)body {
}

- (void) startSingletons:(BEMixedRealityMode *) mixedRealityMode {
    // update scene
    [Scene main].scene = mixedRealityMode.sceneKitScene;
    [Scene main].rootNode = mixedRealityMode.worldNodeWhenRelocalized;

    // event manager
    [[EventManager main] start];
}

- (void) startWithMixedRealityMode:(BEMixedRealityMode *) mixedRealityMode {
    [self startSingletons:mixedRealityMode];
    [self updateSingletons:mixedRealityMode withDeltaTime:1.f];
    
    for( GKEntity * entity in self.entities ) {
        for( GKComponent * component in entity.components ) {
            if( [component conformsToProtocol:@protocol(ComponentProtocol)]) {
                [(GKComponent <ComponentProtocol> *)component start];
            }
        }
    }
}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds mixedRealityMode:(BEMixedRealityMode *) mixedRealityMode {
#ifdef ENABLE_COMPONENT_PROFILING
    // Check global time averages, and every second report runtime cost.
    static mach_timebase_info_data_t sTimebaseInfo;
    if( sTimebaseInfo.denom == 0 ) mach_timebase_info(&sTimebaseInfo);
    
    uint64_t start = mach_absolute_time();
#endif // ENABLE_COMPONENT_PROFILING

    [self updateSingletons:mixedRealityMode withDeltaTime:(NSTimeInterval)seconds];

    for( GKEntity * entity in self.entities ) {
        [entity updateWithDeltaTime:seconds];
    }

#ifdef ENABLE_COMPONENT_PROFILING
    uint64_t end = mach_absolute_time();
    uint64_t elapsedNano = (end-start) * (uint64_t)sTimebaseInfo.numer / (uint64_t)sTimebaseInfo.denom;
    
    // Integrate timing averages, and throttle to 1-update per second.
    static uint64_t avgElapsed = 0;
    static int avgElapsedCount = 0;
    
    avgElapsed += elapsedNano;
    avgElapsedCount++;
    
    static uint64_t throttleStart = 0;
    uint64_t throttleElapsedNano = (end - throttleStart) * (uint64_t)sTimebaseInfo.numer / (uint64_t)sTimebaseInfo.denom;
    if( throttleElapsedNano > 1000000000L ) {
        avgElapsed /= avgElapsedCount;
        NSLog(@"Scene Cmp: %0.4f (ms)", (double)avgElapsed / 1000000.0 );
        avgElapsed = 0;
        avgElapsedCount = 0;
        
        throttleStart = end;
    }
#endif // ENABLE_COMPONENT_PROFILING
}

- (void)updateAtTime:(NSTimeInterval)time mixedRealityMode:(BEMixedRealityMode *) mixedRealityMode {
    // update entities
    if(self.previousTimeInterval) {
        NSTimeInterval timeInterval = time - self.previousTimeInterval;
        [self updateWithDeltaTime:timeInterval mixedRealityMode:mixedRealityMode];
    }
    self.previousTimeInterval = time;
}


@end
