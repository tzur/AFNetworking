// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

uniform highp mat4 modelview;
uniform highp mat4 projection;
uniform highp mat3 texture;

attribute highp vec4 position;
attribute highp vec3 texcoord;

void main() {
  texture;
  texcoord;
  gl_Position = projection * modelview * position;
}
