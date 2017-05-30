// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Danny Rosenberg.

uniform sampler2D sourceTexture;

varying highp vec3 vTexcoord;

void main() {
  gl_FragColor = texture2D(sourceTexture, vTexcoord.xy / vTexcoord.z);
}
