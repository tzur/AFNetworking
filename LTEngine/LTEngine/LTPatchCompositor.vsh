// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

uniform highp mat4 modelview;
uniform highp mat4 projection;
uniform bool flipSourceTextureCoordinates;

uniform highp mat3 texture;

attribute highp vec4 position;
attribute highp vec3 texcoord;

varying highp vec2 vSourceTexcoord;
varying highp vec2 vTargetTexcoord;
varying highp vec2 vBaseTexcoord;

void main() {
  texture;
  vec2 flippedTexCoord = texcoord.xy;

  if (flipSourceTextureCoordinates) {
    flippedTexCoord.x = 1.0 - flippedTexCoord.x;
  }

  vSourceTexcoord = flippedTexCoord;
  vTargetTexcoord = texcoord.xy;
  vBaseTexcoord = texcoord.xy;

  gl_Position = projection * modelview * position;
}
