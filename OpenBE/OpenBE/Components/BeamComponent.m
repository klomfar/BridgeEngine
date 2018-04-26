/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2018 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#define BEAM_TRIANGLES 10

#import "BeamComponent.h"
#import "../Utils/Math.h"
#import "../Utils/SceneKitExtensions.h"
#import "../Core/Core.h"
#import "../Core/AudioEngine.h"

@import GLKit.GLKVector3;
@import OpenGLES;
@import Metal;

@interface BeamComponent ()
@property (atomic) float beamActive;
@property (strong) SCNNode * node;

@property(strong) AudioNode *audioLoop;

@end

// Metal Struct
typedef struct  {
    vector_float3 startPos;// Starting beam position
    vector_float3 endPos;  // End beam position
    float width;    // Max beam displacement width
    float height;   // Max beam displacement height
    float active;   // How bright and active is the beam
} OBEScanBeamProperties;

@implementation BeamComponent
{
    OBEScanBeamProperties _shaderProperties; // Metal shader properties
}

- (id) init {
    self = [super init];
    
    self.startPos = GLKVector3Make(0, 0, 0);
    self.endPos = GLKVector3Make(0, 0, 0);
    
    return self;
}

- (void) start {
    [super start];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Beam sound effect.
        self.audioLoop = [[AudioEngine main] loadAudioNamed:@"BeamLoop.caf"];
        _audioLoop.looping = YES;
        _audioLoop.volume = 0;
        [_audioLoop play];
    });

    [self createBeam];
}

- (void) setEnabled:(bool)enabled {
    [super setEnabled:enabled];
    _audioLoop.volume = enabled? MAX(MIN(_beamActive,1.f), 0.f) : 0;
    self.node.hidden = !enabled;
}

- (void) createBeam {
    self.node = [SCNNode node];
    [[Scene main].rootNode addChildNode:self.node];
    self.node.name = @"ScanBeam";
    
    SCNVector3 positions[BEAM_TRIANGLES*3];
    int indices[BEAM_TRIANGLES*3];
    
    for( int i=0; i<BEAM_TRIANGLES; i++ ) {
        float random = (float)drand48();
        
        positions[i*3+0] = SCNVector3Make(0, 0, random);
        positions[i*3+1] = SCNVector3Make(1, 1, random);
        positions[i*3+2] = SCNVector3Make(1, 0, random);
        
        indices[i*3+0] = i*3+0;
        indices[i*3+1] = i*3+1;
        indices[i*3+2] = i*3+2;
    }
    
    SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithVertices:positions count:(BEAM_TRIANGLES*3)];
    NSData *indexData = [NSData dataWithBytes:indices length:sizeof(indices)];
    
    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:indexData
                                                                primitiveType:SCNGeometryPrimitiveTypeTriangles
                                                               primitiveCount:BEAM_TRIANGLES
                                                                bytesPerIndex:sizeof(int)];
    SCNGeometry *geometry = [SCNGeometry geometryWithSources:@[vertexSource]
                                                    elements:@[element]];
    self.node.geometry = geometry;
    self.node.categoryBitMask |= RAYCAST_IGNORE_BIT;
    
    
    SCNMaterial * material = [SCNMaterial material];
    material.doubleSided = YES;
    
    self.node.geometry.materials = @[ material ];

    SCNProgram *program;
    if( SceneManager.main.renderingAPI == BEViewRenderingAPIMetal ) {
        program = [SCNProgram openbeMetalProgramWithVertexFunctionName:@"OBEScanBeamVertex"
                                                  fragmentFunctionName:@"OBEScanBeamFragment"];
    } else {
        [self.node.geometry.firstMaterial handleBindingOfSymbol:@"width" usingBlock:^(unsigned int programID, unsigned int location, SCNNode *renderedNode, SCNRenderer *renderer) {
            glUniform1f(location, self.beamWidth);
        }];
        
        [self.node.geometry.firstMaterial handleBindingOfSymbol:@"height" usingBlock:^(unsigned int programID, unsigned int location, SCNNode *renderedNode, SCNRenderer *renderer) {
            glUniform1f(location, self.beamHeight);
        }];
        
        [self.node.geometry.firstMaterial handleBindingOfSymbol:@"active" usingBlock:^(unsigned int programID, unsigned int location, SCNNode *renderedNode, SCNRenderer *renderer) {
            glUniform1f(location, self.beamActive);
        }];
        
        [self.node.geometry.firstMaterial handleBindingOfSymbol:@"startPos" usingBlock:^(unsigned int programID, unsigned int location, SCNNode *renderedNode, SCNRenderer *renderer) {
            glUniform3fv(location, 1, self.startPos.v);
        }];
        
        [self.node.geometry.firstMaterial handleBindingOfSymbol:@"endPos" usingBlock:^(unsigned int programID, unsigned int location, SCNNode *renderedNode, SCNRenderer *renderer) {
            glUniform3fv(location, 1, self.endPos.v);
        }];
        
        [self.node.geometry.firstMaterial handleBindingOfSymbol:@"shaderType" usingBlock:^(unsigned int programID, unsigned int location, SCNNode *renderedNode, SCNRenderer *renderer) {
            glUniform1f(location, 0.f);
        }];
        
        program = [SCNProgram programWithGLShader:@"Shaders/CombinedShader/combinedShader"];
    }
    
    [program setOpaque:NO];

    self.node.geometry.firstMaterial.program = program;
    self.node.geometry.firstMaterial.blendMode = SCNBlendModeAdd;
    self.node.renderingOrder = TRANSPARENCY_RENDERING_ORDER + 90;
    [self.node setCastsShadowRecursively:NO];
}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    if( !self.node.hidden && self.beamActive <= 0.f ) {
        self.node.hidden = YES;
    } else {
        _audioLoop.position = self.node.position;
    }
    
    // Update Beam Metal shader parameters.
    if( SceneManager.main.renderingAPI == BEViewRenderingAPIMetal ) {
        GLKVector3 start = self.startPos;
        _shaderProperties.startPos = simd_make_float3(start.x, start.y, start.z);
        GLKVector3 end = self.endPos;
        _shaderProperties.endPos = simd_make_float3(end.x, end.y, end.z);
        _shaderProperties.width = self.beamWidth;
        _shaderProperties.height = self.beamHeight;
        _shaderProperties.active = self.beamActive;
        NSData* data = [NSData dataWithBytes:&_shaderProperties length:sizeof(OBEScanBeamProperties)];
        [self.node.geometry.firstMaterial setValue:data forKey:@"beam"];
    }
}

- (void) setActive:(float)active beamWidth:(float)width beamHeight:(float)height {
    self.beamActive = active;
    self.beamWidth = width;
    self.beamHeight = height;
    _audioLoop.position = self.node.position;
    _audioLoop.volume = saturatef(active);
    self.node.hidden = (active <= 0.f);
}

@end
