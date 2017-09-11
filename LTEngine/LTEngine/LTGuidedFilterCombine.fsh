// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

// Source texture.
uniform highp sampler2D sourceTexture;
// Guided filter scale coefficients texture.
uniform highp sampler2D scaleTexture;
// Guided filter shift coefficients texture.
uniform highp sampler2D shiftTexture;
// If set to YES the shader will ignore the guide color and use its luminance instead.
uniform bool useGuideLuminance;

varying highp vec2 vTexcoord;


// Returns \c rgbColor luminance channel in YIQ colorspace.
highp float colorLuminance(mediump vec3 rgbColor) {
  const highp vec3 kRGBToYPrime = vec3(0.299, 0.587, 0.114);
  return dot(rgbColor, kRGBToYPrime);
}

void main() {
  highp vec4 guide = texture2D(sourceTexture, vTexcoord);
  if (useGuideLuminance) {
    guide.rgb = vec3(colorLuminance(guide.rgb));
  }
  highp vec3 scale = texture2D(scaleTexture, vTexcoord).rgb;
  highp vec3 shift = texture2D(shiftTexture, vTexcoord).rgb;
  gl_FragColor = vec4(scale * guide.rgb + shift, guide.a);
}
