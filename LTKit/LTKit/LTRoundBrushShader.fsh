// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#extension GL_EXT_shader_framebuffer_fetch : require

uniform mediump sampler2D sourceTexture;

uniform highp float opacity;
uniform highp float flow;
uniform highp vec4 intensity;

varying highp vec2 vTexcoord;

void main() {
  mediump vec4 previousColor = gl_LastFragData[0];
  highp vec4 newColor = texture2D(sourceTexture, vTexcoord).r * intensity;
  gl_FragColor = clamp(min(previousColor + flow * newColor, opacity), previousColor, vec4(1.0));
}
