/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2018 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "../Core/EventComponentProtocol.h"
#import "../Core/CoreMotionComponentProtocol.h"
#import "../Core/GeometryComponent.h"

#import "RobotBehaviourComponent.h"
#import "PhysicsContactAudioComponent.h"

@class SelectableModelComponent;
@class GazeComponent;

@interface FetchEventComponent : GeometryComponent <ComponentProtocol, EventComponentProtocol, CoreMotionComponentProtocol>

@property(nonatomic, strong) RobotBehaviourComponent * robotBehaviourComponent;
@property(nonatomic, weak) PhysicsContactAudioComponent * physicsContactAudio;
@property(nonatomic) BOOL endExperience;
@property(nonatomic) SelectableModelComponent *powerOutlet;

- (bool) handleMotionTransform:(GLKMatrix4)transform;

@end
