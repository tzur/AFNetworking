// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

uniform highp mat4 modelview;
uniform highp mat4 projection;
uniform highp mat3 texture;
uniform highp vec2 grainScaling;
uniform highp vec2 grainOffset;

attribute highp vec4 position;
attribute highp vec3 texcoord;

varying highp vec2 vTexcoord;
varying highp vec2 vGrainTexcoord;

void main() {
  vTexcoord = (texture * vec3(texcoord.xy, 1.0)).xy;
  vGrainTexcoord = vTexcoord * grainScaling - grainOffset;
  gl_Position = projection * modelview * position;
}
