// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

uniform highp mat4 projection;

attribute highp vec4 position;
attribute highp vec3 texcoord;

varying highp vec3 vTexcoord;

void main() {
  vTexcoord = texcoord;
  gl_Position = projection * position;
}
