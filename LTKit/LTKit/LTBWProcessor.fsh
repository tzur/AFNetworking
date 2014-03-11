// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

uniform sampler2D sourceTexture;
uniform sampler2D grainTexture;
uniform sampler2D vignettingTexture;
uniform sampler2D frameTexture;

varying highp vec2 vTexcoord;
varying highp vec2 vGrainTexcoord;

void main() {
  grainTexture;
  vignettingTexture;
  frameTexture;
  
  mediump vec4 tone = texture2D(sourceTexture, vTexcoord);
  mediump vec3 grain = texture2D(grainTexture, vGrainTexcoord).rgb;
  
  tone.rgb = tone.rgb + 2.5 * (grain - 0.5);
  
  gl_FragColor = tone;
}
