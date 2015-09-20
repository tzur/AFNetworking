// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

uniform highp mat4 modelview;
uniform highp mat4 projection;

uniform highp mat3 texture;
uniform highp mat3 frontMatrix;
uniform highp mat3 maskMatrix;

attribute highp vec4 position;
attribute highp vec3 texcoord;

varying highp vec2 vTexcoord;
varying highp vec2 vBackTexcoord;

void main() {
  vTexcoord = texcoord.xy;
  vBackTexcoord = (texture * texcoord).xy;
  gl_Position = projection * modelview * position;
}
