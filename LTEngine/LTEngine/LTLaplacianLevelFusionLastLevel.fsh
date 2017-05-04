// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#extension GL_EXT_shader_framebuffer_fetch : require

uniform mediump sampler2D sourceTexture;
uniform mediump sampler2D weightMap;

varying highp vec2 vTexcoord;

void main() {
  mediump vec4 baseSample = texture2D(sourceTexture, vTexcoord);
  mediump float weight = texture2D(weightMap, vTexcoord).r;
  mediump vec4 gaussianDC = vec4(vec3(weight), 1.0) * baseSample;

  gl_FragColor = gaussianDC + gl_LastFragData[0];
}
