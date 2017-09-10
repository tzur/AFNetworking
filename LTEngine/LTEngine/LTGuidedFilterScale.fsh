// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

// Texture with averaged input image.
uniform highp sampler2D sourceTexture;
// Texture with averaged squared guide image.
uniform highp sampler2D meanSquareGuideTexture;
// Texture with average of guide image multiplied by input image.
uniform highp sampler2D meanInputMultipliedByGuideTexture;
// Texture with averaged guide image.
uniform highp sampler2D meanGuideTexture;
// Controls smoothness. Larger value results in more intense smoothing.
uniform highp float smoothingDegree;

varying highp vec2 vTexcoord;

void main() {
  highp vec3 meanI = texture2D(meanGuideTexture, vTexcoord).rgb;
  highp vec3 corrI = texture2D(meanSquareGuideTexture, vTexcoord).rgb;
  highp vec3 varI = max(corrI - meanI * meanI, 0.0);
  highp vec3 meanP = texture2D(sourceTexture, vTexcoord).rgb;
  highp vec3 corrIP = texture2D(meanInputMultipliedByGuideTexture, vTexcoord).rgb;
  highp vec3 covIP = corrIP - meanI * meanP;
  highp vec3 scale = covIP / (varI + vec3(smoothingDegree));
  gl_FragColor = vec4(clamp(scale, -10.0, 10.0), 1.0); 
}
