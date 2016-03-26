// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

uniform sampler2D textureA;
uniform sampler2D textureB;

varying highp vec2 vTexcoord;

void main() {
  gl_FragColor = texture2D(textureA, vTexcoord) - texture2D(textureB, vTexcoord);
}
