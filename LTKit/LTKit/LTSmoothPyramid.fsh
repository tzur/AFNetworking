// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

uniform sampler2D sourceTexture;

uniform highp vec2 texelStep;
varying highp vec2 vTexcoord;

void main() {
  mediump vec4 sample0 = texture2D(sourceTexture, vTexcoord);
  mediump vec4 sample1 = texture2D(sourceTexture, vTexcoord + vec2(texelStep.x, 0));
  mediump vec4 sample2 = texture2D(sourceTexture, vTexcoord + vec2(0, texelStep.y));
  mediump vec4 sample3 = texture2D(sourceTexture, vTexcoord - vec2(texelStep.x, 0));
  mediump vec4 sample4 = texture2D(sourceTexture, vTexcoord - vec2(0, texelStep.y));
  
  gl_FragColor = 0.2 * (sample0 + sample1 + sample2 + sample3 + sample4);
}

