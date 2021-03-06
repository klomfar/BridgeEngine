/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2018 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "SceneKitExtensions.h"
#import "../Core/Core.h"

#import <BridgeEngine/BridgeEngine.h>

@import GLKit;
@import Metal;

#pragma mark - SceneKit

@implementation SceneKit

+ (NSString*) pathForResourceNamed:(NSString*)resourceName withExtension:(NSString*)type
{
    NSString* resourcePath = nil;
//    NSLog(@"looking for %@", resourceName);
    for (NSBundle* resourceBundle in @[
                                       [NSBundle mainBundle], // The app bundle.
                                       [NSBundle bundleForClass:[BEMixedRealityMode class]], // The Bridge Engine framework bundle.
                                       [NSBundle bundleForClass:self] // The bundle that contains the final target including this code. It may be one the two above.
                                       ])
    {
        // inDirectory:nil makes the search run recursively through folders

        resourcePath = [resourceBundle pathForResource:resourceName ofType:type ];
        
        if (resourcePath)
            return resourcePath;
        
        NSString *assetName = [@"OpenBE.scnassets/" stringByAppendingString:resourceName];
        assetName = [resourceBundle pathForResource:assetName ofType:type inDirectory:nil];
        
        if (assetName)
            return assetName;
    }
    
    return resourcePath;
}

+ (NSString*) pathForResourceNamed:(NSString*)resourceName
{
    return [SceneKit pathForResourceNamed:resourceName withExtension:nil];
}

+ (NSString*)pathForImageResourceNamed:(NSString*)imageName
{
    NSString* resourcePath = [SceneKit pathForResourceNamed:imageName];
    
    if (resourcePath == nil)
        resourcePath = [SceneKit pathForResourceNamed:imageName withExtension:@"png"];
    
    if (resourcePath == nil)
        resourcePath = [SceneKit pathForResourceNamed:[@"Textures" stringByAppendingPathComponent:imageName]];
    
    return resourcePath;
}

+ (NSURL*)URLForResource:(NSString*)resourceName withExtension:(NSString*)ext
{
    return [NSURL fileURLWithPath:[SceneKit pathForResourceNamed:resourceName withExtension:ext]];
}

+ (SCNNode*) loadNodeFromSceneNamed:(NSString*)sceneName
{
    SCNScene* scene = [SCNScene sceneNamed:sceneName];
    if (!scene)
    {
        NSLog(@"Could not load scene named: %@", sceneName);
        assert(scene);
    }
    
    // return first child node
    return [scene.rootNode.childNodes objectAtIndex:0];
}

@end

#pragma mark - SCNProgram

@implementation SCNProgram (OpenBEExtensions)

/// Deprecated: use programWithGLShader
/// Will be removed in later releases.
+ (SCNProgram *)programWithShader:(NSString *)shaderName {
    return [SCNProgram programWithGLShader:shaderName];
}


/// Auto load the shaderName.vsh and shaderName.fsh
/// and prepare the program with attribute semantics
/// Attributes: position, normal, textureCoordinate
/// Uniforms: modelViewProjection, modelView, normalTransform, projection
+ (SCNProgram *)programWithGLShader:(NSString *)shaderName {
    NSURL *vertexShaderURL   = [SceneKit URLForResource:shaderName withExtension:@"vsh"];
    NSURL *fragmentShaderURL = [SceneKit URLForResource:shaderName withExtension:@"fsh"];
    NSString *vertexShader   = [[NSString alloc] initWithContentsOfURL:vertexShaderURL
                                                              encoding:NSUTF8StringEncoding
                                                                 error:NULL];
    NSString *fragmentShader = [[NSString alloc] initWithContentsOfURL:fragmentShaderURL
                                                              encoding:NSUTF8StringEncoding
                                                                 error:NULL];
    
    // Create a shader program and assign the shaders
    SCNProgram *program = [SCNProgram program];
    program.vertexShader   = vertexShader;
    program.fragmentShader = fragmentShader;
    
    // Attributes (position, normal, texture coordinate)
    [program setSemantic:SCNGeometrySourceSemanticVertex
               forSymbol:@"position"
                 options:nil];
    [program setSemantic:SCNGeometrySourceSemanticNormal
               forSymbol:@"normal"
                 options:nil];
    [program setSemantic:SCNGeometrySourceSemanticTexcoord
               forSymbol:@"textureCoordinate"
                 options:nil];
    
    // Uniforms (the three different transformation matrices)
    [program setSemantic:SCNModelViewProjectionTransform
               forSymbol:@"modelViewProjection"
                 options:nil];
    [program setSemantic:SCNModelViewTransform
               forSymbol:@"modelView"
                 options:nil];
    [program setSemantic:SCNNormalTransform
               forSymbol:@"normalTransform"
                 options:nil];
    [program setSemantic:SCNProjectionTransform
               forSymbol:@"projection"
                 options:nil];
    
    return program;
}


/// Auto load the OpenBE metal shader from
/// the openbe.metal library
+ (SCNProgram*)openbeMetalProgramWithVertexFunctionName:(NSString*)vertexName
                             fragmentFunctionName:(NSString*)fragmentName {

    // Use the bundle holds the SceneKit -Extensions- class, like the OpenBE.framework.
    NSBundle *bundle = [NSBundle bundleForClass:SceneKit.class];
    static id<MTLLibrary> openbeLib = nil;
    if( openbeLib == nil ) {
        openbeLib = [MTLCreateSystemDefaultDevice() newDefaultLibraryWithBundle:bundle error:nil];
    }
    
    SCNProgram * program = [SCNProgram program];
    program.vertexFunctionName = vertexName;
    program.fragmentFunctionName = fragmentName;
    program.library = openbeLib;
    return program;
}

@end

#pragma mark - SCNNode

@implementation SCNNode (OpenBEExtensions)

// An iOS 9 friendly implementation of SCNNode enumerateHierarchyUsingBlock
- (void)_enumerateHierarchyUsingBlock:(void (^)(SCNNode *node, BOOL *stop))block
{
    static bool hasiOS10OrAbove = false;
    static dispatch_once_t once;
    dispatch_once(&once, ^ {
        hasiOS10OrAbove = [[UIDevice currentDevice].systemVersion floatValue] > 10.0;
    });
    
    if(hasiOS10OrAbove)
        [self enumerateHierarchyUsingBlock:block];
    else
    {
        // iOS 9 friendly implementation:
        bool stop = false;
        block(self, &stop);
        if(!stop)
        {
            [self enumerateChildNodesUsingBlock:block];
        }
    }
}

- (void) printSceneHierarchy {
    [self printHierarchyWithPrefix:@""];
}

- (void) printHierarchyWithPrefix:(NSString *)prepend {
    NSString * newPrepend = [prepend stringByAppendingString:@"  "];
    
    for( SCNNode * node in self.childNodes ) {
        NSString * string = [prepend stringByAppendingString:@" - "];
        if( node.name ) {
            NSLog( @"%@ %@ (%ld)", string, node.name, (long)node.renderingOrder );
        } else {
            NSLog( @"%@ %@ (%ld)", string, node, node.renderingOrder );
        }
        if( [node.childNodes count] ) {
            [node printHierarchyWithPrefix:newPrepend];
        }
    }
}

- (void) setCastsShadowRecursively:(bool)castShadow {
    self.castsShadow = castShadow;
    for( SCNNode * child in self.childNodes ) {
        [child setCastsShadowRecursively:castShadow];
    }
}

- (void) setCategoryBitMaskRecursively:(int)bitmask {
    self.categoryBitMask = bitmask;
    for( SCNNode * child in self.childNodes ) {
        [child setCategoryBitMaskRecursively:bitmask];
    }
}

- (void) setRenderingOrderRecursively:(int)order {
    self.renderingOrder = order;
    for( SCNNode * child in self.childNodes ) {
        [child setRenderingOrderRecursively:order];
    }
}

- (void) setOpacityRecursively:(float)opacity {
    self.opacity = opacity;
    for( SCNNode * child in self.childNodes ) {
        [child setOpacityRecursively:opacity];
    }
}

- (void) setEmissionRecursively:(id)emissionValue {
    [self.geometry.firstMaterial.emission setContents:emissionValue];
    for( SCNNode * child in self.childNodes ) {
        [child setEmissionRecursively:emissionValue];
    }
}

- (void) setWritesToDepthBufferRecursively:(BOOL)doDepthTest {
    self.geometry.firstMaterial.writesToDepthBuffer = doDepthTest;
    for( SCNNode * child in self.childNodes ) {
        [child setWritesToDepthBufferRecursively:doDepthTest];
    }
}

- (void) setReadsFromDepthBufferRecursively:(BOOL)doDepthTest {
    self.geometry.firstMaterial.readsFromDepthBuffer = doDepthTest;
    for( SCNNode * child in self.childNodes ) {
        [child setReadsFromDepthBufferRecursively:doDepthTest];
    }
}

+ (SCNNode*) firstNodeFromSceneNamed:(NSString*)sceneName
{
    NSString* resourcePath = [SceneKit pathForResourceNamed:sceneName];
    
    if (resourcePath == nil)
        resourcePath = [SceneKit pathForResourceNamed:[@"Models" stringByAppendingPathComponent:sceneName]];
    
    if (resourcePath == nil)
        resourcePath = [SceneKit pathForResourceNamed:[@"Models/Animations" stringByAppendingPathComponent:sceneName]];
    
    SCNScene* scene = [SCNScene sceneWithURL:[NSURL fileURLWithPath:resourcePath]
                                     options:nil
                                       error:nil];
    if (!scene)
    {
        NSLog(@"Could not load scene named: %@", sceneName);
        assert(scene);
    }
    
    // return first child node
    
    return [scene.rootNode.childNodes objectAtIndex:0];
}

@end

#pragma mark - SCNScene

@implementation SCNScene (OpenBEExtensions)

+ (SCNScene*)sceneInFrameworkOrAppNamed:(NSString*)sceneName
{
    NSString* resourcePath = [SceneKit pathForResourceNamed:sceneName];
    if (resourcePath == nil)
        resourcePath = [SceneKit pathForResourceNamed:[@"Models" stringByAppendingPathComponent:sceneName]];
    
    SCNScene* scene = [SCNScene sceneWithURL:[NSURL fileURLWithPath:resourcePath]
                                     options:nil
                                       error:nil];
    if (!scene)
    {
        NSLog(@"Could not load scene named: %@", sceneName);
        assert(scene);
    }
    
    return scene;
}

- (void) setSkyboxImages:(NSArray*)images {
    self.background.contents = images;
}

@end
