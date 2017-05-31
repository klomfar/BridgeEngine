/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

// See "AVAudioEngine 3D Audio Example" for reference implementation
// https://developer.apple.com/library/content/samplecode/AVAEGamingExample/Introduction/Intro.html

#import "../Core/Core.h"
#import "AudioEngine.h"
#import "../Utils/SceneKitExtensions.h"

@interface AudioEngine () {
    NSMutableDictionary<NSString*,AudioNode*>  *_nodeDictionary;
    NSMutableDictionary<NSString*,AVAudioPCMBuffer*>  *_bufferDictionary;

    // mananging session and configuration changes
    BOOL _isSessionInterrupted;
    BOOL _isConfigChangePending;
}

@property(nonatomic, strong) AVAudioEngine *engine;
@property(nonatomic, strong) AVAudioEnvironmentNode *environment;

- (instancetype) init;

@end

@implementation AudioEngine

+ (AudioEngine*) main {
    static AudioEngine *mainEngine = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        void (^initEngine)() = ^{
            mainEngine = [[AudioEngine alloc] init];
        };
        
        // Avoid dead-locking and make sure we init AudioEngine on main thread.
        if( [NSThread isMainThread] ) {
            initEngine();
        } else {
            dispatch_sync(dispatch_get_main_queue(), initEngine);
        }
    });
    
    return mainEngine;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSAssert([NSThread isMainThread], @"AudioEngine called outside of main thread");
        //store audioNodes to play in a dictionary
        _nodeDictionary = [[NSMutableDictionary alloc] init];
        _bufferDictionary = [[NSMutableDictionary alloc] init];

        // Set up the audio category so we always hear the sound.
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
        //create audio engine to play sounds
        _engine = [[AVAudioEngine alloc] init];
        
        // Create a dummy player node and hook it up.  See if we get an un-elegant solution to bad audio.
        AVAudioPlayerNode *dummy = [[AVAudioPlayerNode alloc] init];
        [_engine attachNode:dummy];
        [_engine connect:dummy to:_engine.mainMixerNode format:nil];
        dummy = nil;
        
        _environment = [[AVAudioEnvironmentNode alloc] init];
        [_engine attachNode:_environment];

        // Get notifications about changes in output configuration
        [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioEngineConfigurationChangeNotification
            object:_engine
            queue:[NSOperationQueue mainQueue]
            usingBlock:^(NSNotification *note)
        {
            if (!_isSessionInterrupted) {
//                NSLog(@"Received a %@ notification!", AVAudioEngineConfigurationChangeNotification);
//                NSLog(@"Re-wiring connections and starting once again");
                [self makeEngineConnections];
                [self startEngine];
            }
            else {
                // if we've received this notification, something has changed and the engine has been stopped
                // re-wire all the connections and start the engine
                _isConfigChangePending = YES;
//                NSLog(@"Session is interrupted, deferring changes");
            }
        }];

        // Set up the environment with a bit of reverb.
        [_environment setVolume:1.0];
        [_environment setOutputVolume:1.0];
//        _environment.reverbParameters.enable = YES;
//        _environment.reverbParameters.level = -20;
//        [_environment.reverbParameters loadFactoryReverbPreset:AVAudioUnitReverbPresetMediumRoom];
//        [_environment setReverbBlend:0.2];

        [self makeEngineConnections];
        [self startEngine];
    }
    return self;
}
/**
 * If we're connecting with a multichannel format, we need to pick a multichannel rendering algorithm
 */
- (AVAudio3DMixingRenderingAlgorithm) audioRenderingAlgo {
    NSAssert([NSThread isMainThread], @"AudioEngine called outside of main thread");
    return AVAudio3DMixingRenderingAlgorithmSphericalHead;
}

- (void)makeEngineConnections
{
    NSAssert([NSThread isMainThread], @"AudioEngine called outside of main thread");
//    NSLog(@"Making AudioEngine connections");
    [_engine connect:_environment to:_engine.mainMixerNode format:nil];
    
    // Set up the 3d audio environment
    AVAudio3DMixingRenderingAlgorithm renderingAlgo = self.audioRenderingAlgo;
    
    // Connect all of the players to the audio environment, and reset the rendering algorithm to match.
    for( NSString *nodeName in _nodeDictionary ) {
        AudioNode* node = _nodeDictionary[nodeName];
        [_engine connect:node.player to:_environment format:nil];
        node.player.renderingAlgorithm = renderingAlgo;
    }
}


- (void) startEngine {
    NSAssert([NSThread isMainThread], @"AudioEngine called outside of main thread");
    NSError *error = nil;
    BOOL audioStartResult = [_engine startAndReturnError:&error];
    if(audioStartResult == NO || error != nil) {
        NSLog(@"Audio Engine Start Error: %@", error.localizedDescription);
    } else {
//        NSLog(@"Audio Engine Started OK");
    }
}

#pragma mark - Buffer Management



/**
 * Load and cache sound buffers by name from <resources>/Sounds/<named>
 * THEAD SAFE
 */
- (AVAudioPCMBuffer*)bufferForName:(NSString*)named {
    NSAssert([NSThread isMainThread], @"AudioEngine called outside of main thread");
    AVAudioPCMBuffer *aBuff = _bufferDictionary[named];
    if(aBuff == nil ) {
        // Attempt loading the audio subfolder.
        NSString *soundPath = [SceneKit pathForResourceNamed:[@"Sounds" stringByAppendingPathComponent:named]];
        NSURL *aURL = [NSURL fileURLWithPath:soundPath];
        
        AVAudioFile *aFile = [[AVAudioFile alloc] initForReading:aURL error:nil];
        if( aFile == nil ) {
            return nil;
        }
        
        //read file to buffer
        aBuff = [[AVAudioPCMBuffer alloc] initWithPCMFormat:[aFile processingFormat] frameCapacity:(unsigned int)[aFile length]];
        [aFile readIntoBuffer:aBuff error:nil];
        
        // Keep buffers cached, do house keeping on main thread.
        _bufferDictionary[named] = aBuff;
    }
    
    return aBuff;
}

/**
 * Create a player node with buffer.
 * RUN ON MAIN THREAD ONLY
 */
- (AudioNode*) nodeWithBuffer:(AVAudioPCMBuffer*)buffer named:(NSString*)named {
    NSAssert([NSThread isMainThread], @"AudioEngine playerWithBuffer:named: called outside of main thread");
    AudioNode *node = _nodeDictionary[named];
    if(node == nil) {
        //make a node for the sound
        AVAudioPlayerNode *player = [[AVAudioPlayerNode alloc] init];
        node = [[AudioNode alloc] initWithName:named buffer:buffer player:player];
        
        //attach the node to audio engine first
        [_engine attachNode:player];
        
        //assign format to node
        [_engine connect:player to:_environment format:[buffer format]];

        // Assign the current rendering algorithm of choice.
        player.renderingAlgorithm = self.audioRenderingAlgo;

        // Add this to the player pool.
        _nodeDictionary[named] = node;
    }

    return node;
}

/**
 * Single shot audio playback at volume.
 * THREAD SAFE
 */
- (void) playAudio:(NSString*)named atVolume:(float)volume {
    dispatch_async(dispatch_get_main_queue(), ^{
        //occasionally, this can get called if the audio engine is not running.
        if (![_engine isRunning]){
            NSLog(@"AudioEngine: AudioEngine not running, could not play audio: %@", named);
            return;
        }
        
        AVAudioPCMBuffer  *buffer = [self bufferForName:named];
        if( buffer==nil ) {
            NSLog(@"AudioEngine: Could not play, missing audio: %@", named);
            return;
        }
        
        AudioNode *node = [self nodeWithBuffer:buffer named:named];

        //  Schedule the one-shot for immediate playback.
        [node.player scheduleBuffer:buffer atTime:nil options:AVAudioPlayerNodeBufferInterrupts completionHandler:nil];
        node.player.volume = volume;
        [node.player play];
    });
}

/**
 * Load an audio file and return an audio node.
 * RUN ON MAIN THREAD ONLY
 */
- (AudioNode*) loadAudioNamed:(NSString*)named {
    NSAssert([NSThread isMainThread], @"AudioEngine loadAudioNamed: called outside of main thread");

    AVAudioPCMBuffer  *buffer = [self bufferForName:named];
    if( buffer==nil ) {
        NSLog(@"AudioEngine: Could not load, missing audio: %@", named);
        return nil;
    }

    // Make a stand-alone AudioNode.
    AudioNode *audioNode = [self nodeWithBuffer:buffer named:named];
    return audioNode;
}

/**
 * Take in the Camera node, and update the listener position and orientation.
 * THREAD SAFE
 */
- (void) updateListenerFromCameraNode:(SCNNode*)cameraNode {
    SCNVector3 sp = cameraNode.position;
    
    SCNQuaternion so = cameraNode.orientation;
    GLKQuaternion go = GLKQuaternionMake( so.x, so.y, so.z, so.w );
    GLKVector3 gfwd = GLKQuaternionRotateVector3(go, GLKVector3Make(0, 0, -1));
    GLKVector3 gup = GLKQuaternionRotateVector3(go, GLKVector3Make(0, 1, 0));
    

    AVAudio3DVector afwd = AVAudioMake3DVector(gfwd.x, gfwd.y, gfwd.z);
    AVAudio3DVector aup = AVAudioMake3DVector(gup.x, gup.y, gup.z);

    dispatch_async(dispatch_get_main_queue(), ^{
        [_environment setListenerPosition:AVAudioMake3DPoint(sp.x, sp.y, sp.z)];
        [_environment setListenerVectorOrientation:AVAudioMake3DVectorOrientation(afwd, aup)];
    });
}


#pragma mark - AVAudioSession

- (void)initAVAudioSession
{
    NSAssert([NSThread isMainThread], @"AudioEngine initAVAudioSession called outside of main thread");
    NSError *error;
    
    // Configure the audio session
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];

    // set the session category
    bool success = [sessionInstance setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (!success) NSLog(@"Error setting AVAudioSession category! %@\n", [error localizedDescription]);
     
    const NSInteger desiredNumChannels = 8; // for 7.1 rendering
    const NSInteger maxChannels = sessionInstance.maximumOutputNumberOfChannels;
    if (maxChannels >= desiredNumChannels) {
        success = [sessionInstance setPreferredOutputNumberOfChannels:desiredNumChannels error:&error];
        if (!success) NSLog(@"Error setting PreferredOuputNumberOfChannels! %@", [error localizedDescription]);
    }
    
    
    // add interruption handler
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:sessionInstance];
    
    // we don't do anything special in the route change notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRouteChange:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:sessionInstance];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMediaServicesReset:)
                                                 name:AVAudioSessionMediaServicesWereResetNotification
                                               object:sessionInstance];
    
    // activate the audio session
    success = [sessionInstance setActive:YES error:&error];
    if (!success) NSLog(@"Error setting session active! %@\n", [error localizedDescription]);
}

- (void)handleInterruption:(NSNotification *)notification
{
    UInt8 theInterruptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
    
    NSLog(@"Session interrupted > --- %s ---\n", theInterruptionType == AVAudioSessionInterruptionTypeBegan ? "Begin Interruption" : "End Interruption");
    
    if (theInterruptionType == AVAudioSessionInterruptionTypeBegan) {
        _isSessionInterrupted = YES;
        
        //stop the playback of the nodes
        for( NSString *playerName in _nodeDictionary ) {
            AVAudioPlayerNode* player = _nodeDictionary[playerName].player;
            [player stop];
        }
    }

    if (theInterruptionType == AVAudioSessionInterruptionTypeEnded) {
        // make sure to activate the session
        NSError *error;
        bool success = [[AVAudioSession sharedInstance] setActive:YES error:&error];
        if (!success)
            NSLog(@"AVAudioSession set active failed with error: %@", [error localizedDescription]);
        else {
            _isSessionInterrupted = NO;
            if (_isConfigChangePending) {
                //there is a pending config changed notification
                NSLog(@"Responding to earlier engine config changed notification. Re-wiring connections and starting once again");
                [self makeEngineConnections];
                [self startEngine];
                
                _isConfigChangePending = NO;
            }
            else {
                // start the engine once again
                [self startEngine];
            }
        }
    }
}

- (void)handleRouteChange:(NSNotification *)notification
{
    UInt8 reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    AVAudioSessionRouteDescription *routeDescription = [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
    
    NSLog(@"Route change:");
    switch (reasonValue) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"     NewDeviceAvailable");
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            NSLog(@"     OldDeviceUnavailable");
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            NSLog(@"     CategoryChange");
            NSLog(@"     New Category: %@", [[AVAudioSession sharedInstance] category]);
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            NSLog(@"     Override");
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            NSLog(@"     WakeFromSleep");
            break;
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            NSLog(@"     NoSuitableRouteForCategory");
            break;
        default:
            NSLog(@"     ReasonUnknown");
    }
    
    NSLog(@"Previous route:\n");
    NSLog(@"%@", routeDescription);
}

- (void)handleMediaServicesReset:(NSNotification *)notification
{
    // if we've received this notification, the media server has been reset
    // re-wire all the connections and start the engine
    NSLog(@"Media services have been reset!");
    NSLog(@"Re-wiring connections and starting once again");
    
    [self initAVAudioSession];
    [self createEngineAndAttachNodes];
    [self makeEngineConnections];
    [self startEngine];
}

/**
 * Re-establish the audio engine and connections.
 */
- (void)createEngineAndAttachNodes
{
    _engine = [[AVAudioEngine alloc] init];
    [_engine attachNode:_environment];
    
    for( NSString *nodeName in _nodeDictionary ) {
        AudioNode *node = _nodeDictionary[nodeName];
        [_engine attachNode:node.player];
        
        // Restart playback of looping nodes.
        if( node.looping ) {
            NSLog(@"Resuming Loopig Audio: %@", nodeName);
            [node play];
        }
    }
}

@end

#pragma mark - AudioNode

@interface AudioNode () {
    float _volume;
}

@property(nonatomic, strong) AVAudioPCMBuffer *buffer;
@end

@implementation AudioNode

- (instancetype)initWithName:(NSString*)name buffer:(AVAudioPCMBuffer*)buffer player:(AVAudioPlayerNode*) player
{
    self = [super init];
    if (self) {
        be_assert(buffer && player, "Null on buffer or player");
        self.name = name;
        self.buffer = buffer;
        self.player = player;
        _volume = player.volume;
    }
    return self;
}

- (void) setVolume:(float)volume {
    _volume = volume;
    _player.volume = volume;
}

- (float) volume {
    return _volume;
}

- (float) duration {
    return _buffer.frameLength / _buffer.format.sampleRate;
}

- (void) setPosition:(SCNVector3)position {
    _player.position = AVAudioMake3DPoint(position.x, position.y, position.z);
}

- (SCNVector3) position {
    AVAudio3DPoint p = _player.position;
    return SCNVector3Make(p.x, p.y, p.z);
}


/// Play the audio.  THREAD SAFE
- (void) play {
    dispatch_async(dispatch_get_main_queue(), ^{
        if( _looping ) {
            [_player scheduleBuffer:_buffer atTime:nil options:AVAudioPlayerNodeBufferLoops|AVAudioPlayerNodeBufferInterrupts completionHandler:nil];
        } else {
            [_player scheduleBuffer:_buffer atTime:nil options:AVAudioPlayerNodeBufferInterrupts completionHandler:nil];
        }
        [_player play];
//        NSLog(@"%@ Playing %@ (%@)", [NSThread isMainThread]?@"MAIN":@"BG", _name, _player);
    });
}

// Stop the audio from playing.  THREAD SAFE
- (void) stop {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_player stop];
    });
}
@end
