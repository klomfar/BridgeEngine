/*
    This file is part of the Structure SDK.
    Copyright © 2018 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#pragma once

#import <BridgeEngine/BridgeEngineAPI.h>
#import <UIKit/UIView.h>

//------------------------------------------------------------------------------

typedef NS_ENUM(NSUInteger, BEViewRenderingAPI) {
    BEViewRenderingAPIOpenGLES2,
    BEViewRenderingAPIMetal
};
//------------------------------------------------------------------------------

/**
 @class BEView
 @abstract A BEView is a subclass of UIView that can display a Mixed Reality Scene through Bridge Engine.
 */
BE_API
@interface BEView : UIView

/// The prefersMetalRenderingAPI BOOL is used to set preferredRenderingAPI from interface builder.
/// Default is NO
@property (nonatomic) IBInspectable BOOL prefersMetalRenderingAPI;

/// The preferred rendering API for the view, using during setup.  This may be rejected if your hardware doesn't support the API.
@property (nonatomic) BEViewRenderingAPI preferredRenderingAPI;

/// The actual rendering API selected by the view.
@property (nonatomic, readonly) BEViewRenderingAPI renderingAPI;

- (instancetype)initWithRenderingAPI:(BEViewRenderingAPI)preferredRenderingAPI;

@end
