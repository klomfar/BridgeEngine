/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2018 Occipital, Inc. All rights reserved.
 http://structure.io
 */

// This shader is used to make an object look like a projection.

// IMPORTANT NOTE: this shader is actually inlined in CombinedShader
// to workaround a SceneKit issue.

varying lowp float rim;
void main()
{
    lowp vec4 ambientLight = vec4(55.0/255.0, 179.0/255.0, 246.0/255.0, 1.0) * 0.35;
    lowp vec4 rimLight = vec4(1.0, 1.0, 1.0, 0.5) * pow(rim, 1.5);
    gl_FragColor = ambientLight + rimLight;
}
