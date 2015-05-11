// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

uniform highp mat4 modelview;
uniform highp mat3 sourceModelview;
uniform highp mat3 targetModelview;
uniform highp mat4 projection;
uniform highp mat3 texture;
uniform bool flip;

varying mediump vec4 vMembraneColor;
varying mediump vec2 vSourceCoord;
varying mediump vec2 vTargetCoord;
varying mediump vec2 vTexcoord;

attribute vec4 position;
attribute vec2 texcoord;
attribute vec4 color;

void main() {
  texture;

  vMembraneColor = color;
  mediump vec3 flippedTexCoord = vec3(texcoord.xy, 1.0);
  flippedTexCoord.x = !flip ? flippedTexCoord.x : 1.0 - flippedTexCoord.x;
  vSourceCoord = (sourceModelview * flippedTexCoord).xy;
  vTargetCoord = (targetModelview * vec3(texcoord, 1.0)).xy;
  vTexcoord = (targetModelview * vec3(texcoord, 1.0)).xy;
  gl_Position = projection * modelview * position;
}
