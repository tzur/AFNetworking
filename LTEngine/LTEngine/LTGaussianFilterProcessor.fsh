// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

// @NUMBER_OF_TAPS@ should be replaced at the run-time before compiling the shader.
// Should be the same as in .vsh
const lowp int kNumberOfTaps = @NUMBER_OF_TAPS@;
const lowp int kCenterTap = (kNumberOfTaps - 1) / 2;

uniform highp float expDenominator;
uniform highp float spatialUnit;
uniform highp mat4 tonalMatrix;
uniform sampler2D sourceTexture;

varying highp vec2 vTexcoords[kNumberOfTaps];

highp float gaussian(highp float x) {
  return exp(-x * x / expDenominator);
}

void main() {
  highp vec3 colorAccumulator = vec3(0.0);
  highp float totalWeight = 0.0;
  for (mediump int i = 0; i < kNumberOfTaps; ++i) {
    highp float weight = gaussian(spatialUnit * float(i - kCenterTap));
    colorAccumulator += weight * texture2D(sourceTexture, vTexcoords[i]).rgb;
    totalWeight += weight;
  }
  gl_FragColor = vec4(colorAccumulator / totalWeight,
      texture2D(sourceTexture, vTexcoords[kCenterTap]).a);
}
