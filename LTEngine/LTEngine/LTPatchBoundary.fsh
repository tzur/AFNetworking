// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

const int SAMPLE_COUNT = 5;
const highp float KERNEL_CENTER = -4.0;

uniform lowp sampler2D sourceTexture;
uniform highp float threshold;

varying mediump vec2 vSampleCoords[SAMPLE_COUNT];

highp vec4 sampleWithZeroBoundary(highp vec2 sampleCoords) {
  // Return 0.0 outside the texture boundary to ensure white regions that are adjacent to the
  // texture edges will have a boundary after this process.
  if (any(lessThan(sampleCoords, vec2(0.0))) ||
      any(greaterThan(sampleCoords, vec2(1.0)))) {
    return vec4(0.0);
  }

  // Binarize input (if threshold < x <= 1, x = 1, 0 <= x < threshold, x = 0).
  return vec4(greaterThan(texture2D(sourceTexture, sampleCoords), vec4(threshold)));
}

void main() {
  /// Filter using discrete Laplacian kernel:
  /// [0  1 0]
  /// [1 -4 1]
  /// [0  1 0]
  highp vec4 value = KERNEL_CENTER * sampleWithZeroBoundary(vSampleCoords[0]) +
                     sampleWithZeroBoundary(vSampleCoords[1]) +
                     sampleWithZeroBoundary(vSampleCoords[2]) +
                     sampleWithZeroBoundary(vSampleCoords[3]) +
                     sampleWithZeroBoundary(vSampleCoords[4]);
  value = -value * (1.0 - step(0.0, value));

  gl_FragColor = vec4(value.rgb, 1.0);
}
