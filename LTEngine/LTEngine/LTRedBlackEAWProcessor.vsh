// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

const lowp int SAMPLE_COUNT = 5;

uniform highp mat4 modelview;
uniform highp mat4 projection;
uniform highp mat3 texture;

uniform highp vec2 texelOffset;
uniform highp vec2 texelScaling;

attribute highp vec4 position;
attribute highp vec3 texcoord;

varying highp vec2 vSampleCoords[SAMPLE_COUNT];
varying highp vec2 vSampleCoordInput;

void main() {
  highp vec2 sampleCoord = (texture * vec3(texcoord.xy, 1.0)).xy;

  vSampleCoordInput = sampleCoord;

  vSampleCoords[0] = sampleCoord * texelScaling;
  vSampleCoords[1] = sampleCoord * texelScaling + vec2(-1, 0) * texelOffset;
  vSampleCoords[2] = sampleCoord * texelScaling + vec2(1, 0) * texelOffset;
  vSampleCoords[3] = sampleCoord * texelScaling + vec2(0, -1) * texelOffset;
  vSampleCoords[4] = sampleCoord * texelScaling + vec2(0, 1) * texelOffset;

  gl_Position = projection * modelview * position;
}
