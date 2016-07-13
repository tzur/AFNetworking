// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

uniform sampler2D sourceTexture;

varying highp vec2 vTexcoord;
varying highp float vFactor;

void main() {
  gl_FragColor = vec4(vFactor * texture2D(sourceTexture, vTexcoord).rgb, 1);
}
