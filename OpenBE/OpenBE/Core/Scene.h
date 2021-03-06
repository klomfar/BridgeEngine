/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2018 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <GameplayKit/GameplayKit.h>
#import <SceneKit/SceneKit.h>

@interface Scene : NSObject

@property(nonatomic, weak) SCNNode *rootNode;
@property(nonatomic, weak) SCNScene *scene;

/**
 * All objects that should respond to gaze,
 * and don't have a physical body.
 * This is needed because hitTestWithSegmentFromPoint is
 * extremely (really) slow for objects without an physical body
 */
@property(nonatomic, strong) SCNNode *rootNodeForGaze;

+ (Scene *) main;

@end
