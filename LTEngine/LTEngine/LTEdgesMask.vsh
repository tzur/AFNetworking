// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

const int SAMPLE_COUNT = 2;

attribute vec4 position;
attribute vec3 texcoord;

uniform highp mat4 modelview;
uniform highp mat4 projection;
uniform highp mat3 texture;
uniform highp vec2 texelOffset;

varying mediump vec2 vSampleCoords[SAMPLE_COUNT];
varying highp vec2 vTexcoord;

void main() {
  vTexcoord = (texture * vec3(texcoord.xy, 1.0)).xy;
  vSampleCoords[0] = vTexcoord + vec2(1.0, 0.0) * texelOffset;
  vSampleCoords[1] = vTexcoord + vec2(0.0, 1.0) * texelOffset;
  
  gl_Position = projection * modelview * position;
}
