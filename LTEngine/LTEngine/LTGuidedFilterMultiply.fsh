// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

// Source texture.
uniform highp sampler2D sourceTexture;
uniform highp sampler2D secondTexture;
uniform bool sourceTextureSingleChannel;
uniform bool secondTextureSingleChannel;

varying highp vec2 vTexcoord;

void main() {
  highp vec4 color1 = texture2D(sourceTexture, vTexcoord);
  highp vec4 color2 = texture2D(secondTexture, vTexcoord);
  if (sourceTextureSingleChannel) {
    color1 = vec4(vec3(color1.r), 1.0);
  }
  if (secondTextureSingleChannel) {
    color2 = vec4(vec3(color2.r), 1.0);
  }
  gl_FragColor = color1 * color2;
}
