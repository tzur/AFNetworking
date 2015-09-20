// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

uniform highp mat4 modelview;
uniform highp mat4 projection;
uniform highp mat3 texture;

attribute highp vec4 position;
attribute highp vec3 texcoord;

varying highp vec2 vTexcoord;

void main() {
  vTexcoord = (texture * vec3(texcoord.xy, 1.0)).xy;
  gl_Position = projection * modelview * position;
}
