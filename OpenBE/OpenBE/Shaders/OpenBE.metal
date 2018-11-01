/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2018 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#include <metal_stdlib>
#include <metal_common>
#include <simd/simd.h>

using namespace metal;
#include <SceneKit/scn_metal>

#pragma mark - Utilities

#define HASHSCALE3 float3(443.897, 441.423, 437.195)

//  2 hashed values out, 1 linear value in...
float2 hash21(float p)
{
    float3 p3 = fract(float3(p) * HASHSCALE3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract(float2((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y));
}

#pragma mark - Scan Beam Shader

struct OBEScanBeamVertexIn {
    float3 position [[ attribute(SCNVertexSemanticPosition) ]];
};

struct OBEScanBeamVertexOut {
    float4 position [[ position ]];
    float2 uv [[ attribute(SCNVertexSemanticTexcoord0) ]];
};

struct OBEScanBeamNodeBuffer {
    float4x4 modelViewProjectionTransform;
};

struct OBEScanBeamProperties {
    float3 startPos;// Starting beam position
    float3 endPos;  // End beam position
    float width;    // Max beam displacement width
    float height;   // Max beam displacement height
    float active;   // How bright and active is the beam
};

vertex OBEScanBeamVertexOut OBEScanBeamVertex(
    OBEScanBeamVertexIn in [[ stage_in ]],
//    constant SCNSceneBuffer& scn_frame [[buffer(0)]],
    constant OBEScanBeamNodeBuffer& scn_node [[buffer(1)]],
    constant OBEScanBeamProperties& beam [[buffer(2)]] )
{
    OBEScanBeamVertexOut out;
    
    float4 startPosScreen = scn_node.modelViewProjectionTransform * float4(beam.startPos, 1.0);
    
    float3 pos = beam.endPos;

    // Calculate our perpendiculars to our beam line.
    float3 forward = normalize(beam.endPos-beam.startPos);
    float3 up = normalize( cross( forward, float3(0,1,0) ) );
    float3 right = normalize( cross( up, forward ));
    up = normalize( cross( forward, right ) );

    /// Use a hashing function to create jagged displacements along the beam line.
    float2 h = 2.*(hash21(in.position.z + in.position.y)-.5);
    pos += up * (beam.width * h.x) + right * (beam.height * h.y);
    
    float4 endPosScreen = scn_node.modelViewProjectionTransform * float4(pos, 1.0);
    
    
    out.position = mix( startPosScreen, endPosScreen, in.position.x );
    
    //   out.position.z = 0.001;
    
    out.uv = in.position.xy;

    return out;
}

fragment half4 OBEScanBeamFragment(
   OBEScanBeamVertexOut in [[ stage_in ]],
   constant OBEScanBeamProperties& beam [[buffer(2)]] )
{
    float2 alpha  = smoothstep( float2(0.), float2(.1,.4), in.uv) * smoothstep( float2(1.), float2(.8, .6), in.uv);
    float lum = smoothstep( 0., .2, beam.active) * smoothstep( 1., .5, beam.active);
    
    return half4( .5, .7, 1., .5 ) * (alpha.x * alpha.y * lum);
}

//struct

#pragma mark - Fixed Size Reticle Shader

struct OBEFixedSizeReticleVertexIn {
    float3 position [[ attribute(SCNVertexSemanticPosition) ]];
};

struct OBEFixedSizeReticleVertexOut {
    float4 position [[ position ]];
    float2 uv [[ attribute(SCNVertexSemanticTexcoord0) ]];
};

struct OBEFixedSizeReticleNodeBuffer {
    float4x4 modelViewProjectionTransform;
};

struct OBEFixedSizeReticleProperties {
    float active;
};

vertex OBEFixedSizeReticleVertexOut OBEFixedSizeReticleVertex(
      OBEFixedSizeReticleVertexIn in [[ stage_in ]],
      constant SCNSceneBuffer& scn_frame [[buffer(0)]],
      constant OBEFixedSizeReticleNodeBuffer& scn_node [[buffer(1)]] )
{
    OBEFixedSizeReticleVertexOut out;
    
    // Start at dead-center, but get the clip space projection.
    out.position = scn_node.modelViewProjectionTransform * float4(0,0,0,1);
    
    float4x4 projection = scn_frame.projectionTransform;
    float2 offset = in.position.xy;
    // Account for render target aspect ratio
    offset.y *= fabs( projection[1].y / projection[0].x);
    
    // Apply clip-space projection to the screen offset
    out.position.xy += offset * out.position.w;

    // Nearest z, but it's really not needed.
    out.position.z = 0;

    // Get the normalized 4-corners of the quad by using the sign of each vertex position.
    out.uv = sign(in.position.xy);
    
    return out;
}

fragment half4 OBEFixedSizeReticleFragment(
    OBEFixedSizeReticleVertexOut in [[ stage_in ]],
    constant OBEFixedSizeReticleProperties& reticle_properties [[buffer(2)]] )
{
    float r = length(in.uv);
    
    // Light Green when active, white when inactive.
    float3 activeBlend = reticle_properties.active>.5 ? float3( .7,1.,.7):float3(1.);
    
    // Calculate a smaller color fall-off between radius 0.6-0.7
    float3 col = mix( activeBlend, float3(0), smoothstep(0.6, 0.7, r));
    
    // Outer alpha fall-off a little larger so we get a black outer ring
    // between radius 0.8-0.9
    float alpha = 1. - smoothstep(.8, .9, r);
    
    return half4(col.x, col.y, col.z, alpha);
}

#pragma mark - Projection Shader
// This shader is used to make an object look like a projection.

struct OBEProjectionVertexIn {
    float3 position [[ attribute(SCNVertexSemanticPosition) ]];
    float3 normal [[ attribute(SCNVertexSemanticNormal) ]];
};

struct OBEProjectionVertexOut {
    float4 position [[ position ]];
    float rim;
};

struct OBEProjectionNodeBuffer {
    float4x4 modelViewProjectionTransform;
    float4x4 modelViewTransform;
};

vertex OBEProjectionVertexOut OBEProjectionVertex(
    OBEProjectionVertexIn in [[ stage_in ]],
    constant SCNSceneBuffer& scn_frame [[buffer(0)]],
    constant OBEProjectionNodeBuffer& scn_node [[buffer(1)]]
)
{
    OBEProjectionVertexOut out;
    
    out.position =  scn_node.modelViewProjectionTransform * float4(in.position, 1.0);
    
    float3 n = normalize(scn_node.modelViewTransform * float4(in.normal, 0)).xyz;  // convert normal to view space
    float3 viewPos = (scn_node.modelViewTransform * float4(in.position, 1.0)).xyz; // convert position to view space
    float3 v = normalize(-viewPos);                                     // vector towards eye
    out.rim = (1.0 - max(dot(v, n), 0.0)) * length(in.normal);             // rim shading (w/fallback if normal isn't set)
    
    return out;
}

fragment half4 OBEProjectionFragment(
    OBEProjectionVertexOut in [[ stage_in ]]
)
{
//    half4 ambientLight =
//    half4 rimLight = half4(1.0, 1.0, 1.0, 0.1) * 0.1;
    return half4(55.0/255.0, 179.0/255.0, 246.0/255.0, 0.00) * pow(in.rim, 1.5) * 0.25;
}


#pragma mark - Scan Environment Shader

/// Note: This shader is used by Bridge Engine as defined in BEShader, so it doesn't have any of the SceneKit predefined formats

struct BECustomEnvironmentShaderUniforms
{
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 modelViewMatrix;
};

struct OBEScanEnvironmentOut {
    float4 position [[position]];
    float3 worldPosition;
    
    float scanTime;
    float scanDuration;
    float scanRadius;
    float3 scanLocation;
};

struct OBEScanEnvironmentUniformsMetal {
    float scanTime;
    float scanDuration;
    float scanRadius;
    float3 scanLocation;
};

vertex OBEScanEnvironmentOut OBEScanEnvironmentVertex(const device packed_float3* vertex_array [[ buffer(0) ]],
                                                      const device packed_float3* normals_array [[ buffer(1) ]],
                                                      constant BECustomEnvironmentShaderUniforms&  uniforms [[ buffer(2) ]],
                                                      constant OBEScanEnvironmentUniformsMetal&  customUniforms [[ buffer(3) ]],
                                                      unsigned int vid [[ vertex_id ]])
{
    OBEScanEnvironmentOut vertOut;
    
    vertOut.worldPosition = vertex_array[vid];
    vertOut.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * float4(vertOut.worldPosition, 1.0);
    
    vertOut.scanTime = customUniforms.scanTime;
    vertOut.scanDuration = customUniforms.scanDuration;
    vertOut.scanRadius = customUniforms.scanRadius;
    vertOut.scanLocation = customUniforms.scanLocation;
    
    return vertOut;
}

fragment half4 OBEScanEnvironmentFragment(OBEScanEnvironmentOut fragIn [[stage_in]])
{
    const float LinesPerMeter = 25.0;
    const float ScanPeakDuration = 0.1;
    const float ScanFadeDuration = 1.0;
    
    float4 fragPos = float4(fragIn.worldPosition, 1.0);

    // Calculate the decay parameters related to scanning time (0 min, to ScanRampDuration peak, to 1.0 sec min)
    float strength = smoothstep( 0.0, ScanPeakDuration, fragIn.scanTime) * (1.0 - smoothstep( fragIn.scanDuration - ScanFadeDuration, fragIn.scanDuration, fragIn.scanTime));
    float maxDist = fragIn.scanRadius * strength;

    float disty = fragIn.scanLocation.y - fragPos.y;
    float dist = distance( fragPos.xz, fragIn.scanLocation.xz ) + (step(disty, -0.5) + step(0.5, disty)) * 10.0;
     
    float distanceFromScanPoint = clamp(1.0 - smoothstep(0.5 * maxDist, maxDist, dist), 0.0, 1.0);
     
    // worldStableScanY refers to the scanning lines.
    float worldStableScanY = (fragPos.y) * LinesPerMeter;
    float emissionAmount = (1.0 - smoothstep( 0., 0.15, abs( fract( worldStableScanY ) - .5) ));
    
    /* This color has been converted from sRGB to Linear space so it looks correct in metal (vs. the opengl shader)
     sRGB to Linear Conversion:
     
     bool3 cutoff = (color.rgb <= 0.04045);
     float3 higher = pow((color.rgb + 0.055)/1.055, 2.4);
     float3 lower = color.rgb/12.92;
     color.rgb = select(higher, lower, cutoff);
     */
    float3 color = float3(0.4479, 1.0, 0.4479) * emissionAmount;
    float alpha = (0.5 + 0.5 * emissionAmount) * distanceFromScanPoint;
    
    return half4(float4(color, alpha));
}
