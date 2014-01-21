// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

const int SAMPLE_COUNT = 7;
const mediump float SAMPLE_COUNT_FLOAT = 7.0;

uniform lowp sampler2D originalTexture;
uniform lowp sampler2D sourceTexture;

varying mediump vec2 vSampleCoords[SAMPLE_COUNT];

void main() {
  // Read current fragment's color.
  highp vec4 color = texture2D(originalTexture, vSampleCoords[(SAMPLE_COUNT - 1) / 2]);

  highp vec4 colorSum = vec4(0.0);
  for (int i = 0; i < SAMPLE_COUNT; i++) {
    // Sum the neigbourhood pixels
    colorSum += texture2D(sourceTexture, vSampleCoords[i]);
  }
  
  gl_FragColor = colorSum / SAMPLE_COUNT_FLOAT;
}
