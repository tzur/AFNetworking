// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#extension GL_EXT_shader_framebuffer_fetch : require

uniform sampler2D sourceTexture;

varying highp vec2 vTexcoord;

void main() {
  mediump vec4 previousColor = gl_LastFragData[0];
  mediump vec4 newColor = texture2D(sourceTexture, vTexcoord);
  gl_FragColor = clamp(previousColor + newColor, 0.0, 1.0);
}
