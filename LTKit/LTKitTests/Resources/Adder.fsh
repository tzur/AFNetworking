// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

uniform sampler2D sourceTexture;
uniform highp float value;

varying highp vec2 vTexcoord;

void main() {
  gl_FragColor = texture2D(sourceTexture, vTexcoord) + vec4(value, value, value, 0.0);
}
