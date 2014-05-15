// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

uniform highp mat4 modelview;
uniform highp mat4 projection;

attribute highp vec4 position;
attribute highp vec4 shadowMaskAndWidth;
attribute highp vec3 edge01;
attribute highp vec3 edge12;
attribute highp vec3 edge20;
attribute highp vec4 color;
attribute highp vec4 shadowColor;
attribute highp vec3 barycentric;

varying highp vec2 vPosition;
varying highp vec4 vShadowMaskAndWidth;
varying highp vec3 vEdge01;
varying highp vec3 vEdge12;
varying highp vec3 vEdge20;
varying highp vec4 vColor;
varying highp vec4 vShadowColor;
varying highp vec3 vBarycentric;

void main() {
  vPosition = position.xy;
  vShadowMaskAndWidth = shadowMaskAndWidth;
  vEdge01 = edge01;
  vEdge12 = edge12;
  vEdge20 = edge20;
  vColor = color;
  vShadowColor = shadowColor;
  vBarycentric = barycentric;
  gl_Position = projection * modelview * position;
}
