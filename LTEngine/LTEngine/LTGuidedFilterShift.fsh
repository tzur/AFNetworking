// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

// Texture with averaged input image.
uniform highp sampler2D sourceTexture;

uniform highp sampler2D meanGuideTexture;

// Scale coefficients texture.
uniform highp sampler2D scaleTexture;

uniform bool shiftValues;

varying highp vec2 vTexcoord;

void main() {
  highp vec3 meanP = texture2D(sourceTexture, vTexcoord).rgb;
  highp vec3 scale = texture2D(scaleTexture, vTexcoord).rgb;
  highp vec3 meanI = texture2D(meanGuideTexture, vTexcoord).rgb;
  // Revert the values shift done while downsampling the image and the guide.
  if (shiftValues) {
    meanP += 0.5;
    meanI += 0.5;
  }

  gl_FragColor = vec4(meanP - scale * meanI, 1.0);
}
