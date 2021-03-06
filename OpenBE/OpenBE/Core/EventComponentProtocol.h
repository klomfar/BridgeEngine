/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2018 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <GameplayKit/GameplayKit.h>
#import <SceneKit/SceneKit.h>
#import "ComponentProtocol.h"

@class GazeComponent;

/**
 * Responders for hit events.
 * Button = 0, if touch input
 * Button = 1, for controller clicking
 */
@protocol EventComponentProtocol <ComponentProtocol>

/**
 * @return not used
 *         Future:
 *         YES to indicate event should go up the responder chain.
 *         NO to indicate event was handled.
 */
- (bool) touchBeganButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit;
- (bool) touchMovedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit;
- (bool) touchEndedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit;
- (bool) touchCancelledButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit;

@optional
- (void) setPause:(bool)pausing;
- (void) gazeStart:(GazeComponent*)gaze intersection:(SCNHitTestResult *)hit;
- (void) gazeStay:(GazeComponent*)gaze intersection:(SCNHitTestResult *)hit;
- (void) gazeExit:(GazeComponent*)gaze;

@end

