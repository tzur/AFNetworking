// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

uniform highp mat4 modelview;
uniform highp mat4 projection;
uniform highp mat3 texture;
uniform highp vec2 grainScaling;
uniform highp mat2 grungeRotation;
attribute highp vec4 position;
attribute highp vec3 texcoord;
uniform highp mat2 lightLeakRotation;

varying highp vec2 vTexcoord;
varying highp vec2 vLightLeakTexcoord;
varying highp vec2 vGrainTexcoord;

void main() {
  vTexcoord = (texture * vec3(texcoord.xy, 1.0)).xy;
  // Rotate by multiples of 90 degress around the center (and not origin) in order to avoid negative
  // coordinates.
  vLightLeakTexcoord = 0.5 + lightLeakRotation * (vTexcoord - 0.5);
  vGrainTexcoord = vTexcoord * grainScaling;
  gl_Position = projection * modelview * position;
}
