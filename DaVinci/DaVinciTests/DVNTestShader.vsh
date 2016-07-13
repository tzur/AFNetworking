// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

uniform highp mat4 projection;

attribute highp vec3 position;
attribute highp vec2 texcoord;
attribute highp float factor;

varying highp vec2 vTexcoord;
varying highp float vFactor;

void main() {
  vTexcoord = texcoord;
  vFactor = factor;
  gl_Position = projection * vec4(position, 1);
}
