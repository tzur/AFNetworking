// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

uniform highp mat4 modelview;
uniform highp mat4 projection;

attribute highp vec4 position;
attribute highp vec2 offset;
attribute highp vec4 lineBounds;
attribute highp vec4 shadowBounds;
attribute highp vec4 color;
attribute highp vec4 shadowColor;

varying highp vec2 vOffset;
varying highp vec4 vLineBounds;
varying highp vec4 vShadowBounds;
varying highp vec4 vColor;
varying highp vec4 vShadowColor;

void main() {
  vOffset = offset;
  vLineBounds = lineBounds;
  vShadowBounds = shadowBounds;
  vColor = color;
  vShadowColor = shadowColor;
  gl_Position = projection * modelview * position;
}
