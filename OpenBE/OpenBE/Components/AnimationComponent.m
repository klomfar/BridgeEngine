/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "AnimationComponent.h"
#import "RobotMeshControllerComponent.h"
#import "../Utils/ComponentUtils.h"
#import "../Utils/SceneKitExtensions.h"

@interface AnimationComponent ()
//@property (weak) GeometryComponent * geometryComponent;
@property (weak) RobotMeshControllerComponent * robotMeshComponent;
@end

@implementation AnimationComponent

+ (CAAnimation*) animationWithSceneNamed:(NSString*)name {
    NSURL *sceneURL;

// DAE files will not load at runtime.  They must be converted to SCN archive format.
//  And, even then the APIs are returning nil when trying to enumerate the animations.
//    // Try Documents/Animations/ first.
//    NSFileManager *fm = [NSFileManager defaultManager];
//    NSURL *documentsURL = [[fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
//    NSURL *docAnimationsURL = [documentsURL URLByAppendingPathComponent:@"Animations"];
//
//    sceneURL = [docAnimationsURL URLByAppendingPathComponent:name];
//    if( [fm fileExistsAtPath:sceneURL.path] == NO ) {
//        sceneURL = [[NSBundle bundleForClass:self] URLForResource:name withExtension:nil];
//        if( sceneURL == nil ) {
//            NSLog(@"Failed to load animationWithSceneNamed: %@", name );
//            return nil;
//        }
//    }
    sceneURL = [SceneKit URLForResource:[@"Models/Animations" stringByAppendingPathComponent:name] withExtension:nil ];

    if( sceneURL == nil ) {
        NSLog(@"Failed to load animationWithSceneNamed: %@", name );
        return nil;
    }

    // NOTE: SCNSceneSourceAnimationImportPolicyPlayUsingSceneTimeBase is very important to make animations work,
    // otherwise it will use system time and won't be in phase with renderAtTime (actually won't show any animation
    // in practice).
    NSDictionary *options = @{SCNSceneSourceAnimationImportPolicyKey:SCNSceneSourceAnimationImportPolicyPlayUsingSceneTimeBase};
    SCNSceneSource *sceneSource = [SCNSceneSource sceneSourceWithURL:sceneURL options:options];
    if( sceneSource == nil ) {
        NSLog(@"Failed to read the sceneSourceWithURL: %@", sceneURL );
        return nil;
    }

    NSArray *animationIdentifiers = [sceneSource identifiersOfEntriesWithClass:[CAAnimation class]];
    if( animationIdentifiers.count == 1 ) {
        CAAnimation *animation = [sceneSource entryWithIdentifier:animationIdentifiers.firstObject withClass:[CAAnimation class]];
        animation.usesSceneTimeBase = NO;
        animation.fadeInDuration = 0.3;
        animation.fadeOutDuration = 0.3;
        return animation;
    } else if( animationIdentifiers.count > 1 ) {
        // Create a single grouped animation.
        CAAnimationGroup *group = [[CAAnimationGroup alloc] init];
        group.fadeInDuration = 0.3;
        group.fadeOutDuration = 0.3;
        
        NSMutableArray *animations = [NSMutableArray arrayWithCapacity:animationIdentifiers.count];
        for( NSString *animID in animationIdentifiers ) {
            CAAnimation *animation = [sceneSource entryWithIdentifier:animID withClass:[CAAnimation class]];
            animation.usesSceneTimeBase = NO;
            [animations addObject:animation];
            
            // Expand the group duration up to the longest animation duration.
            if( group.duration < animation.duration ) {
                group.duration = animation.duration;
            }
        }
        
        group.animations = [animations copy];
        return group;
    } else {
        NSLog(@"No animations found when loading: %@", name);
        return nil;
    }
}

- (void) start {
    self.robotMeshComponent = (RobotMeshControllerComponent * )[ComponentUtils getComponentFromEntity:self.entity ofClass:[RobotMeshControllerComponent class]];
}

// Convenience function for loading an animation from the local bundle.
- (CAAnimation*) loadAnimationNamed:(NSString*)animName {
    return [AnimationComponent animationWithSceneNamed:animName];
}


#pragma mark - Passthru SCNAnimatable to underlying _geometryComponent.node

- (void) addAnimation:(nonnull CAAnimation*)animation forKey:(NSString*)animKey {
    [_robotMeshComponent.robotNode addAnimation:animation forKey:animKey];
}

- (void)removeAllAnimations {
    [_robotMeshComponent.robotNode removeAllAnimations];
}

- (void)removeAnimationForKey:(NSString *)key {
    [_robotMeshComponent.robotNode removeAnimationForKey:key];
}

- (NSArray<NSString *> *) animationKeys {
    return [_robotMeshComponent.robotNode animationKeys];
}

- (nullable CAAnimation *)animationForKey:(NSString *)key {
    return [_robotMeshComponent.robotNode animationForKey:key];
}

- (void)pauseAnimationForKey:(NSString *)key {
    [_robotMeshComponent.robotNode pauseAnimationForKey:key];
}

- (void)resumeAnimationForKey:(NSString *)key {
    [_robotMeshComponent.robotNode resumeAnimationForKey:key];
}

- (BOOL)isAnimationForKeyPaused:(NSString *)key {
    return [_robotMeshComponent.robotNode isAnimationForKeyPaused:key];
}

- (void)removeAnimationForKey:(NSString *)key fadeOutDuration:(CGFloat)duration {
    [_robotMeshComponent.robotNode removeAnimationForKey:key fadeOutDuration:duration];
}

@end
