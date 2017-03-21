// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

uniform highp mat4 modelview;
uniform highp mat4 projection;
uniform bool flipSourceTextureCoordinates;

uniform highp mat3 texture;
uniform highp mat3 targetTextureMat;

attribute highp vec4 position;
attribute highp vec3 texcoord;

varying highp vec2 vSourceTexcoord;
varying highp vec2 vTargetTexcoord;
varying highp vec2 vBaseTexcoord;

void main() {
  vec3 texcoord3 = vec3(texcoord.xy, 1.0);
  vec3 flippedTexCoord = texcoord3;

  if (flipSourceTextureCoordinates) {
    flippedTexCoord.x = 1.0 - flippedTexCoord.x;
  }

  vSourceTexcoord = (texture * flippedTexCoord).xy;
  vTargetTexcoord = (targetTextureMat * texcoord3).xy;
  vBaseTexcoord = texcoord.xy;

  gl_Position = projection * modelview * position;
}
