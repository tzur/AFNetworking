// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

uniform sampler2D sourceTexture;

uniform highp vec2 texelStep;
varying highp vec2 vTexcoord;

const mediump mat3 kernelWeights = mat3(36.0 / 256.0, 24.0 / 256.0, 6.0 / 256.0,
                                        24.0 / 256.0, 16.0 / 256.0, 4.0 / 256.0,
                                        6.0 / 256.0, 4.0 / 256.0, 1.0 / 256.0);

void main() {
  highp float texelStepX, texelStepY;
  highp vec4 sampleSum = vec4(0.0);

  for (int i = -2 ; i <= 2 ; ++i) {
    texelStepX = texelStep.x * float(i);
    int xIndex = int(abs(float(i)));
    for (int j = -2 ; j <= 2 ; ++j) {
      texelStepY = texelStep.y * float(j);
      sampleSum += (kernelWeights[int(abs(float(j)))][xIndex] *
                    texture2D(sourceTexture, vTexcoord + vec2(texelStepX, texelStepY)));
    }
  }

  gl_FragColor = sampleSum;
}
