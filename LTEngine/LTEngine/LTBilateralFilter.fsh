// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

const int SAMPLE_COUNT = 7;

uniform lowp sampler2D originalTexture;
uniform lowp sampler2D sourceTexture;
uniform mediump float rangeSigma;

varying mediump vec2 vSampleCoords[SAMPLE_COUNT];

void main() {
  // Note: Alpha must be constant in the image. Inconsistent results may appear otherwise.

  // Read current fragment's color.
  highp vec4 color = texture2D(originalTexture, vSampleCoords[(SAMPLE_COUNT - 1) / 2]);

  highp float weightedSum = 0.0;
  highp float currentWeight = 0.0;
  highp vec4 neighborColor;
  highp vec4 colorSum = vec4(0.0);

  for (int i = 0; i < SAMPLE_COUNT; i++) {
    // Calculate weights using the original texture.
    neighborColor = texture2D(originalTexture, vSampleCoords[i]);
    currentWeight = exp(-distance(color, neighborColor) / rangeSigma);
    weightedSum += currentWeight;

    // Sum color from the latest processed image.
    colorSum += texture2D(sourceTexture, vSampleCoords[i]) * currentWeight;
  }

  gl_FragColor = colorSum / weightedSum;
}
