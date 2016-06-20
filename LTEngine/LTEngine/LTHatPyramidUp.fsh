// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

uniform sampler2D sourceTexture;

uniform highp vec2 texelStep;
varying highp vec2 vTexcoord;

const lowp mat3 kernelWeights = mat3(36.0 / 64.0, 24.0 / 64.0, 6.0 / 64.0,
                                     24.0 / 64.0, 16.0 / 64.0, 4.0 / 64.0,
                                     6.0 / 64.0, 4.0 / 64.0, 1.0 / 64.0);

void main() {
  int initialX = -2 + int(mod(gl_FragCoord.x, 2.0));
  int initialY = -2 + int(mod(gl_FragCoord.y, 2.0));
  highp float texelStepX, texelStepY;
  mediump vec4 sampleSum = vec4(0.0);

  for (int i = initialX ; i <= 2 ; i += 2) {
    texelStepX = texelStep.x * float(i);
    int xIndex = int(abs(float(i)));
    for (int j = initialY ; j <= 2 ; j +=2) {
      texelStepY = texelStep.y * float(j);
      sampleSum += (kernelWeights[int(abs(float(j)))][xIndex] *
                    texture2D(sourceTexture, vTexcoord + vec2(texelStepX, texelStepY)));
    }
  }

  gl_FragColor = sampleSum;
}

