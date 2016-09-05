// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

uniform lowp sampler2D guideTexture;
uniform lowp sampler2D sourceTexture;
uniform mediump float rangeSigma;
uniform highp vec2 texelOffset;
uniform int kernelSize;

varying highp vec2 vTexcoord;

bool checkCoordsAreInSamplingBounds(in highp vec2 samplingCoords) {
  return !(any(lessThan(samplingCoords, vec2(0.0))) ||
           any(greaterThan(samplingCoords, vec2(1.0))));
}

void main() {
  highp vec4 guideColor = texture2D(guideTexture, vTexcoord);

  highp float weightedSum = 0.0;
  highp float currentWeight = 0.0;
  highp vec4 neighbourColor;
  highp vec4 colorSum = vec4(0.0);
  highp vec2 samplingCoords;
  highp float coordsAreInSamplingBounds;
  
  for (int i = (1 - kernelSize) / 2; i < (kernelSize + 1) / 2; ++i) {
    samplingCoords = vTexcoord + float(i) * texelOffset;
    coordsAreInSamplingBounds = float(checkCoordsAreInSamplingBounds(samplingCoords));
    
    neighbourColor = texture2D(guideTexture, samplingCoords);
    currentWeight = exp(-distance(guideColor.rgb, neighbourColor.rgb) / rangeSigma);
    weightedSum += mix(0.0, currentWeight, coordsAreInSamplingBounds);

    colorSum += mix(vec4(0.0), texture2D(sourceTexture, samplingCoords) * currentWeight,
                    coordsAreInSamplingBounds);
  }

  gl_FragColor = colorSum / weightedSum;
}
