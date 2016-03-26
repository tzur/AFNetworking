// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

const lowp int SAMPLE_COUNT = 7;

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
  
  int step = 0;
  for (lowp int i = 0; i < SAMPLE_COUNT; i++) {
    // Step will get discrete values of [(SAMPLE_COUNT - 1) / 2, (SAMPLE_COUNT + 1) / 2].
    step = (i - ((SAMPLE_COUNT - 1) / 2));
    vSampleCoords[i] = texcoord.xy + float(step) * texelOffset;
  }
}
