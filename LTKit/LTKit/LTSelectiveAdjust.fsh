// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

uniform sampler2D sourceTexture;
uniform sampler2D hsvTexture;

uniform highp float redSaturation;
uniform highp float redLuminance;

varying highp vec2 vTexcoord;

void main() {
  sourceTexture; vTexcoord;
  redSaturation; redLuminance;
//  gl_FragColor = texture2D(sourceTexture, vTexcoord);
  gl_FragColor = vec4(0.9, 0.30, 0.07, 1.0);
}
