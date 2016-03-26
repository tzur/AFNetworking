// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

const int SAMPLE_COUNT = 5;

attribute vec4 position;
attribute vec3 texcoord;

uniform highp mat4 modelview;
uniform highp mat4 projection;
uniform highp mat3 texture;
uniform highp vec2 texelOffset;

varying mediump vec2 vSampleCoords[SAMPLE_COUNT];

void main() {
  texture;

  gl_Position = projection * modelview * position;

  vSampleCoords[0] = texcoord.xy;
  vSampleCoords[1] = texcoord.xy + vec2(0.0, texelOffset.y);
  vSampleCoords[2] = texcoord.xy + vec2(-texelOffset.x, 0.0);
  vSampleCoords[3] = texcoord.xy + vec2(0.0, -texelOffset.y);
  vSampleCoords[4] = texcoord.xy + vec2(texelOffset.x, 0.0);
}
