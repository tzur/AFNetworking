// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

uniform highp sampler2D sourceTexture;
uniform bool useLuminance;
uniform bool shiftValues;

varying highp vec2 vTexcoord;

// Returns \c rgbColor luminance channel in YIQ colorspace.
highp float colorLuminance(mediump vec3 rgbColor) {
  const highp vec3 kRGBToYPrime = vec3(0.299, 0.587, 0.114);
  return dot(rgbColor, kRGBToYPrime);
}

void main() {
  highp vec4 color = texture2D(sourceTexture, vTexcoord);
  if (useLuminance) {
    color.rgb = vec3(colorLuminance(color.rgb));
  }

  // The following reduces numerical artifacts in the variance and covariance calculation.
  if (shiftValues) {
    color.rgb -= 0.5; 
  }
  gl_FragColor = color;
}
