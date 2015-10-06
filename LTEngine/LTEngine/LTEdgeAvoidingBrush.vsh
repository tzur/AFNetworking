// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

uniform highp mat4 modelview;
uniform highp mat4 projection;
uniform highp mat3 texture;

attribute highp vec4 position;
attribute highp vec3 texcoord;

varying highp vec2 vTexcoord;
varying highp vec2 vImgcoord;

void main() {
  vTexcoord = (texture * vec3(texcoord.xy, 1.0)).xy;
  gl_Position = projection * modelview * position;
  vImgcoord = (gl_Position.xy + 1.0) * 0.5;
}
