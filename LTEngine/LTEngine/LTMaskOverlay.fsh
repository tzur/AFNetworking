// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#extension GL_EXT_shader_framebuffer_fetch : require

uniform lowp sampler2D sourceTexture;
uniform lowp sampler2D maskTexture;

uniform lowp vec4 maskColor;
varying highp vec2 vTexcoord;

void main() {
  // To avoid undefined OpenGL behaviors, read from the input texture using gl_LastFragData instead
  // of using the sampler, which is forbidden.
  lowp vec4 image = gl_LastFragData[0];
  sourceTexture;

  lowp vec4 mask = 1.0 - texture2D(maskTexture, vTexcoord);
  lowp vec4 color = mix(image, maskColor, mask.r * maskColor.a);
  gl_FragColor = vec4(color.rgb, 1.0);
}
