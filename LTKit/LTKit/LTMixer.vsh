// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

uniform highp mat4 modelview;
uniform highp mat4 projection;

uniform highp mat3 texture;
uniform highp mat3 frontTextureMat;

attribute highp vec4 position;
attribute highp vec3 texcoord;

varying highp vec2 vBackTexcoord;
varying highp vec2 vFrontTexcoord;
varying highp vec2 vMaskTexcoord;

void main() {
  vec3 texcoord3 = vec3(texcoord.xy, 1.0);

  vBackTexcoord = (texture * texcoord3).xy;
  vFrontTexcoord = (frontTextureMat * texcoord3).xy;
  vMaskTexcoord = texcoord.xy;

  gl_Position = projection * modelview * position;
}
