/*
    This file is part of the Structure SDK.
    Copyright © 2018 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#pragma once

#import <GLKit/GLKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#import <BridgeEngine/BridgeEngineAPI.h>

/// Utility function to create a GL program.
BE_API
GLuint BEShaderLoadProgramFromString (const char *vertex_shader_src,
                                      const char *fragment_shader_src,
                                      const int num_attributes,
                                      GLuint *attribute_ids,
                                      const char **attribute_names);

/// Experimental API to create custom shaders
BE_API

@protocol BridgeEngineShaderDelegate

@end

// -----------------------------------------------
// Custom Metal Shader Protocol

/// This struct will be passed into the vertex function of your metal shader in position buffer[2]
struct BECustomEnvironmentShaderUniforms
{
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 modelViewMatrix;
};

@protocol BridgeEngineMetalShaderDelegate <BridgeEngineShaderDelegate>

/// Vertex Function for the renderer. Will be loaded using an MTLLibrary
- (id<MTLFunction>)vertexFunction;

/// Fragment Function for the renderer. Will be loaded using an MTLLibrary
- (id<MTLFunction>)fragmentFunction;

/// Custom data can be passed into your vertex shader by returning it as customUniforms.
/// This data will be available in the buffer[3] position in your vertex shader.
@optional
- (NSData *)customUniforms;

@end

// -----------------------------------------------
// Custom GL Shader Protocol

@protocol BridgeEngineGLShaderDelegate <BridgeEngineShaderDelegate>

/// This method should load the GL program and fill the properties listed below.
- (void) compile;

/** Prepare the shader uniforms.
 This will get called for every frame, before rendering the mapped area.
 @param projection a 4x4 column-major matrix storing the projection matrix
 @param modelView a 4x4 column-major matrix storing the modelView matrix
 @param depthTexture float texture that was already created by rendering the mapped area mesh.
 @param cameraTexture color texture with the live iOS camera feed.
*/
- (void) prepareWithProjection:(const float*)projection
                     modelview:(const float*)modelView
            depthBufferTexture:(const GLuint)depthTexture
            cameraImageTexture:(const GLuint)cameraTexture;

- (const char *) fragmentShaderSource;
- (const char *) vertexShaderSource;

@property GLuint projectionMatrixLocation;
@property GLuint modelviewMatrixLocation;
@property GLuint glProgram;
@property bool loaded;

@end
