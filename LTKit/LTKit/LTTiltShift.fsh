// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

uniform sampler2D sourceTexture;
uniform sampler2D fineTexture;
uniform sampler2D coarseTexture;
uniform sampler2D dualMaskTexture;

uniform mediump float intensity;

varying highp vec2 vTexcoord;

void main() {
  intensity;
  const lowp vec3 kColorFilter = vec3(0.299, 0.587, 0.114);
  
  lowp vec3 color = texture2D(sourceTexture, vTexcoord).rgb;
  lowp vec3 fine = texture2D(fineTexture, vTexcoord).rgb;
  lowp vec3 coarse = texture2D(coarseTexture, vTexcoord).rgb;
  
  lowp float dualMask = texture2D(dualMaskTexture, vTexcoord).r;
  
  lowp vec3 result = mix(color, coarse, dualMask);
  
  gl_FragColor = vec4(vec3(dualMask), 1.0);
}