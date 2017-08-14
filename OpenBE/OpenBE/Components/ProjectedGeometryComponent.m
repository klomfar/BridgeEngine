//
//  ProjectedGeometryComponent.m
//  Bifrost
//
//  Created by Andrew Zimmer on 7/18/17.
//  Copyright © 2017 Occipital. All rights reserved.
//

#import "ProjectedGeometryComponent.h"
#import "../Utils/SceneKitExtensions.h"

@implementation ProjectedGeometryComponent

- (instancetype)initWithChildNode:(SCNNode *)node {
    if(self = [super init]) {
        self.node = [self createSceneNode];
        [self.node addChildNode:node];
        
        self.node.name = @"ProjectedGeometry";
        self.node.hidden = YES;
        
        [self fixupMaterialsForNode:self.node];
    }
    
    return self;
}

// This recursive method sets the shader type for the component and all child nodes to the projection shader in combined shader.
- (void)fixupMaterialsForNode:(SCNNode *)node {
    [node.geometry.firstMaterial handleBindingOfSymbol:@"shaderType" usingBlock:^(unsigned int programID, unsigned int location, SCNNode *renderedNode, SCNRenderer *renderer) {
        glUniform1f(location, 3.f);
    }];
    
    SCNProgram * program = [SCNProgram programWithShader:@"Shaders/CombinedShader/combinedShader"];
    [program setOpaque:NO];
    
    node.geometry.firstMaterial.program = program;
    node.geometry.firstMaterial.blendMode = SCNBlendModeReplace;
    
    node.geometry.firstMaterial.readsFromDepthBuffer = false;
    node.geometry.firstMaterial.writesToDepthBuffer = false;
    node.renderingOrder = TRANSPARENCY_RENDERING_ORDER + 1000;
    
    node.castsShadow = NO;
    
    [SCNTransaction lock]; /* We reference a zombie if we don't wrap this. */
    for (SCNNode *childNode in node.childNodes) {
        [self fixupMaterialsForNode:childNode];
    }
    [SCNTransaction unlock];
}

@end
