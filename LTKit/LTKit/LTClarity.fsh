// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// This shader applies a clarity effect, by boosting local contrast at medium-fine scale and
// reducing local contrast at coarse scale. Saturation control provided as well, in order to
// compensate for perceived colorfulness changes that result from local contrast boosting.

uniform sampler2D sourceTexture;
uniform sampler2D smoothTexture;

uniform mediump float punch;
uniform mediump float punchBlend;
uniform mediump float flattenA;
uniform mediump float flattenBlend;
uniform mediump float gain;
uniform mediump float saturation;

varying highp vec2 vTexcoord;

mediump float squareSigmoid(in mediump float x, in mediump float a, in mediump float b) {
  return a * x / sqrt(b + x * x);
}

mediump vec3 squareSigmoid(in mediump vec3 x, in mediump float a, in mediump float b) {
  return a * x / sqrt(b + x * x);
}

mediump float addPunch(in mediump float x) {
  return mix(x, squareSigmoid(x, 1.0, 0.03), punchBlend);
}  

mediump float addFlatten(in mediump float x) {
  return mix(x, squareSigmoid(x, flattenA, flattenA), flattenBlend);
}

mediump vec3 addGain(in mediump vec3 x) {
  return mix(x, squareSigmoid(x - 0.25, 1.0, 0.1) + 0.25, gain);
}

void main() {
  const mediump mat3 RGBtoYIQ = mat3(0.299, 0.596, 0.212,
                                     0.587, -0.274, -0.523,
                                     0.114, -0.322, 0.311);
  const mediump mat3 YIQtoRGB = mat3(1.0, 1.0, 1.0,
                                     0.9563, -0.2721, -1.107,
                                     0.621, -0.6474, 1.7046);
  const highp float kIMax = 0.596;
  const highp float kQMax = 0.523;
  const mediump float kGamma = 0.35;
  
  mediump vec4 color = texture2D(sourceTexture, vTexcoord);
  mediump vec3 yiq = RGBtoYIQ * color.rgb;
  
  mediump vec3 smoothColor = texture2D(smoothTexture, vTexcoord).rgb;
  
  // Add gamma to treat underexposed parts better (instead of log, which is too drastic for LDR
  // images).
  smoothColor = pow(smoothColor, vec3(kGamma));
  
  // Tonemap.
  mediump float kBase = 0.7562; // == pow(0.45, kGamma);
  mediump float medium = smoothColor.r;
  mediump float fine = smoothColor.g;
  
  yiq.r = kBase + addFlatten(medium - kBase) + addPunch(fine - medium) + (1.0 - punch) *
      (pow(yiq.r, kGamma) - fine);
  
  // Remove additional gamma.
  yiq.r = pow(yiq.r, 1.0 / kGamma);
  
  // Saturate.
  yiq.g = clamp(yiq.g * saturation, -kIMax, kIMax);
  yiq.b = clamp(yiq.b * saturation, -kQMax, kQMax);
  
  mediump vec4 outputColor = vec4(addGain(YIQtoRGB * yiq), color.a);
  
  gl_FragColor = outputColor;
}
