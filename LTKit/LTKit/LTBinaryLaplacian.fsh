// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

const int SAMPLE_COUNT = 5;
const highp float KERNEL_CENTER = -4.0;

uniform lowp sampler2D sourceTexture;

varying mediump vec2 vSampleCoords[SAMPLE_COUNT];

void main() {
  /// Filter using discrete Laplacian kernel:
  /// [0  1 0]
  /// [1 -4 1]
  /// [0  1 0]
  highp vec4 value = KERNEL_CENTER * texture2D(sourceTexture, vSampleCoords[0]) +
                     texture2D(sourceTexture, vSampleCoords[1]) +
                     texture2D(sourceTexture, vSampleCoords[2]) +
                     texture2D(sourceTexture, vSampleCoords[3]) +
                     texture2D(sourceTexture, vSampleCoords[4]);
  value = 1.0 - step(0.0, value);

  gl_FragColor = vec4(value.rgb, 1.0);
}
