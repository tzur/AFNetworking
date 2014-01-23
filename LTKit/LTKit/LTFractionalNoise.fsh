// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

uniform sampler2D sourceTexture;

uniform highp float amplitude;
uniform highp float seed0;
uniform highp float seed1;
uniform highp float seed2;

varying highp vec2 vTexcoord;

void main() {
  sourceTexture;
  highp float noise = fract(sin(dot(vTexcoord, vec2(9.0 + seed0, 99.0 + seed1))) * 91390.0 + seed2);
  noise = 0.5 + amplitude * (noise - 0.5);
  
  gl_FragColor = vec4(noise, noise, noise, 1.0);
}