// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

uniform highp mat4 modelview;
uniform highp mat4 projection;
uniform highp mat3 texture;
uniform highp vec2 texelOffset;

attribute highp vec4 position;
attribute highp vec3 texcoord;

varying highp vec2 vTexcoord;

void main() {
  texelOffset; // Prevent compilation error.
  vTexcoord = (texture * vec3(texcoord.xy, 1.0)).xy;
  gl_Position = projection * modelview * position;
}
