// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

uniform sampler2D sourceTexture;

varying highp vec2 vTexcoord;

void main() {
  gl_FragColor = texture2D(sourceTexture, vTexcoord);
}
