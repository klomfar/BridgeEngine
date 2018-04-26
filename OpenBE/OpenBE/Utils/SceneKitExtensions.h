/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2018 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <SceneKit/SceneKit.h>

@interface SceneKit : NSObject

// FIXME: move to some resources header something, since these generic methods are not specific to SceneKit.
+ (NSString*)pathForResourceNamed:(NSString*)resourceName withExtension:(NSString*)type;
+ (NSString*)pathForResourceNamed:(NSString*)resourceName; // extension included in the name
+ (NSString*)pathForImageResourceNamed:(NSString*)imageName;
+ (NSURL*)URLForResource:(NSString*)resourceName withExtension:(NSString*)ext;

+ (SCNNode*) loadNodeFromSceneNamed:(NSString*)sceneName;

@end

@interface SCNProgram (OpenBEExtensions)

/// Deprecated: Please use programWithGLShader
/// And be aware this won't work if running in Metal render mode.
/// Will be removed in later releases.
+ (SCNProgram *)programWithShader:(NSString *)shaderName __attribute__((deprecated));

/// Auto load the shaderName.vsh and shaderName.fsh
/// and prepare the program with attribute semantics
/// Attributes: position, normal, textureCoordinate
/// Uniforms: modelViewProjection, modelView, normalTransform, projection
+ (SCNProgram*)programWithGLShader:(NSString *)shaderName;

/// Auto load the OpenBE metal shader from
/// the openbe.metal library
+ (SCNProgram*)openbeMetalProgramWithVertexFunctionName:(NSString*)vertexName
                                   fragmentFunctionName:(NSString*)fragmentName;
@end

@interface SCNScene (OpenBEExtensions)

// Will search in the framework Bundle, not only the main app Bundle.
+ (SCNScene*)sceneInFrameworkOrAppNamed:(NSString*)sceneName;

- (void) setSkyboxImages:(NSArray*)images;

@end

@interface SCNNode (OpenBEExtensions)

+ (SCNNode*)firstNodeFromSceneNamed:(NSString*)sceneName;

/** An iOS 9 friendly implementation of SCNNode enumerateHierarchyUsingBlock */
- (void)_enumerateHierarchyUsingBlock:(void (^)(SCNNode *node, BOOL *stop))block;

- (void) printSceneHierarchy;

- (void) setCastsShadowRecursively:(bool)castShadow;
- (void) setCategoryBitMaskRecursively:(int)bitmask;
- (void) setRenderingOrderRecursively:(int)order;
- (void) setOpacityRecursively:(float)opacity;
- (void) setEmissionRecursively:(id)emissiveValue;
- (void) setWritesToDepthBufferRecursively:(BOOL)doDepthTest;
- (void) setReadsFromDepthBufferRecursively:(BOOL)doDepthTest;

@end

