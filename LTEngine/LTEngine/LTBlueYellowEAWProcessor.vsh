// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

const lowp int SAMPLE_COUNT = 5;

uniform highp mat4 modelview;
uniform highp mat4 projection;
uniform highp mat3 texture;
uniform highp vec2 texelOffset;

attribute highp vec4 position;
attribute highp vec3 texcoord;

varying highp vec2 vSampleCoords[SAMPLE_COUNT];

void main() {
  highp vec2 sampleCoord = (texture * vec3(texcoord.xy, 1.0)).xy;

  vSampleCoords[0] = sampleCoord;
  vSampleCoords[1] = sampleCoord + vec2(-1, -1) * texelOffset;
  vSampleCoords[2] = sampleCoord + vec2(1, -1) * texelOffset;
  vSampleCoords[3] = sampleCoord + vec2(-1, 1) * texelOffset;
  vSampleCoords[4] = sampleCoord + vec2(1, 1) * texelOffset;

  gl_Position = projection * modelview * position;
}
