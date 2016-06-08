// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

uniform highp mat4 projection;

attribute highp vec3 position;
attribute highp vec2 texcoord;

varying highp vec2 vTexcoord;

void main() {
  vTexcoord = texcoord;
  gl_Position = projection * vec4(position, 1);
}
