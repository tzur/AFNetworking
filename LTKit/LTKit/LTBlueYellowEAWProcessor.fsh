// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

const lowp int SAMPLE_COUNT = 5;

uniform sampler2D sourceTexture;
uniform sampler2D currentLevelTexture;

uniform highp vec2 textureSize;

uniform highp vec4 compressionFactor;

varying highp vec2 vSampleCoords[SAMPLE_COUNT];

highp vec4 getValue(sampler2D sampledTexture, highp vec2 sampleCoords) {
  // Return 0.0 outside the texture boundary.
  if (any(lessThan(sampleCoords, vec2(0.0))) || any(greaterThan(sampleCoords, vec2(1.0)))) {
    return vec4(0.0);
  }

  return texture2D(sampledTexture, sampleCoords);
}

highp vec4 dist(highp vec4 a, highp vec4 b) {
  return 1.0 / (abs(a - b) + 0.001);
}

highp vec4 getValueAndWeight(sampler2D sampledTexture, highp vec2 sampleCoords,
                             highp vec4 originalColor, out highp vec4 weight) {
  // Return 0.0 outside the texture boundary.
  if (any(lessThan(sampleCoords, vec2(0.0))) || any(greaterThan(sampleCoords, vec2(1.0)))) {
    weight = vec4(0.0);
    return vec4(0.0);
  }

  highp vec4 color = texture2D(sampledTexture, sampleCoords);
  weight = dist(originalColor, color);
  return color;
}

void main() {
  highp vec4 centerColor = texture2D(currentLevelTexture, vSampleCoords[0]);

  // Sample only from (2:2:end, 2:2:end).
  highp vec2 pixelCoord = vSampleCoords[0] * textureSize;
  bool shouldSample = all(lessThan(mod(pixelCoord + vec2(1.0), 2.0), vec2(1.0)));

  if (shouldSample) {
    highp vec4 w1, w2, w3, w4;
    highp vec4 orig1 = getValueAndWeight(sourceTexture, vSampleCoords[1], centerColor, w1);
    highp vec4 orig2 = getValueAndWeight(sourceTexture, vSampleCoords[2], centerColor, w2);
    highp vec4 orig3 = getValueAndWeight(sourceTexture, vSampleCoords[3], centerColor, w3);
    highp vec4 orig4 = getValueAndWeight(sourceTexture, vSampleCoords[4], centerColor, w4);

    highp vec4 curr1 = getValue(currentLevelTexture, vSampleCoords[1]);
    highp vec4 curr2 = getValue(currentLevelTexture, vSampleCoords[2]);
    highp vec4 curr3 = getValue(currentLevelTexture, vSampleCoords[3]);
    highp vec4 curr4 = getValue(currentLevelTexture, vSampleCoords[4]);

    highp vec4 weightSum = w1 + w2 + w3 + w4;
    highp vec4 d1 = (orig1 * w1 + orig2 * w2 + orig3 * w3 + orig4 * w4) / weightSum;
    highp vec4 d2 = (curr1 * w1 + curr2 * w2 + curr3 * w3 + curr4 * w4) / weightSum;

    gl_FragColor = (centerColor - d1) * compressionFactor + d2;
  } else {
    gl_FragColor = centerColor;
  }
}
