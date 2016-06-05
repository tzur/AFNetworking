// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#extension GL_EXT_shader_framebuffer_fetch : require

uniform sampler2D sourceTexture;

varying highp vec2 vTexcoord;

uniform bool inSituProcessing;
uniform highp mat4 matrix;
uniform highp vec4 constant;

void main() {
  highp vec4 color;
  
  if (inSituProcessing) {
    color = gl_LastFragData[0];
  } else {
    color = texture2D(sourceTexture, vTexcoord);
  }
  
  gl_FragColor = matrix * color + constant;
}
