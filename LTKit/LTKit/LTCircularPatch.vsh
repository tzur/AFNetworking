// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

uniform highp mat4 modelview;
uniform highp mat3 sourceModelview;
uniform highp mat3 targetModelview;
uniform highp mat4 projection;
uniform highp mat3 texture;

varying mediump vec4 vMembraneColor;
varying mediump vec2 vSourceCoord;
varying mediump vec2 vTargetCoord;

attribute vec4 position;
attribute vec2 texcoord;
attribute vec4 color;

void main() {
  texture;

  vMembraneColor = color;
  vSourceCoord = (sourceModelview * vec3(texcoord, 1.0)).xy;
  vTargetCoord = (targetModelview * vec3(texcoord, 1.0)).xy;
  gl_Position = projection * modelview * position;
}
