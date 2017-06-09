/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#import <UIKit/UIKit.h>

#define SETTING_USE_WVL                         @"useWVL"
#define SETTING_COLOR_CAMERA_ONLY               @"colorCameraOnly"
#define SETTING_STEREO_RENDERING                @"stereoRendering"
#define SETTING_SHOW_RENDER_TYPES               @"showRenderTypes"
#define SETTING_STEREO_SCANNING                 @"stereoScanning"
#define SETTING_REPLAY_CAPTURE                  @"replayCapture"
#define SETTING_ENABLE_RECORDING                @"enableRecording"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) UINavigationController *navController;

@end

