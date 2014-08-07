// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

const int kBlendModeNormal = 0;
const int kBlendModeDarken = 1;
const int kBlendModeMultiply = 2;
const int kBlendModeHardLight = 3;
const int kBlendModeSoftLight = 4;
const int kBlendModeLighten = 5;
const int kBlendModeScreen = 6;
const int kBlendModeColorBurn = 7;
const int kBlendModeOverlay = 8;

uniform sampler2D sourceTexture;
uniform sampler2D smoothTexture;
uniform sampler2D grainTexture;
uniform sampler2D vignettingTexture;

// Tone and tinting (colorizing) gradients.
uniform sampler2D toneLUT;
uniform sampler2D colorGradient;

varying highp vec2 vTexcoord;
varying highp vec2 vGrainTexcoord;

uniform int blendMode;
uniform mediump float colorGradientAlpha;
uniform mediump float structure;
uniform mediump float saturation;

uniform mediump float vignettingOpacity;
uniform mediump vec3 vignetteColor;
uniform mediump vec3 grainChannelMixer;
uniform mediump float grainAmplitude;

mediump vec3 normal(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa,
                    in mediump float Da) {
  return Sca + Dca * (1.0 - Sa);
}

mediump vec3 darken(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa,
                    in mediump float Da) {
  return min(Sca * Da, Dca * Sa) + Sca * (1.0 - Da) + Dca * (1.0 - Sa);
}

mediump vec3 multiply(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa,
                      in mediump float Da) {
  return Sca * Dca + Sca * (1.0 - Da) + Dca * (1.0 - Sa);
}

mediump vec3 hardLight(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa,
                       in mediump float Da) {
  mediump vec3 below = 2.0 * Sca * Dca + Sca * (1.0 - Da) + Dca * (1.0 - Sa);
  mediump vec3 above = Sca * (1.0 + Da) + Dca * (1.0 + Sa) - Sa * Da - 2.0 * Sca * Dca;
  
  return mix(below, above, step(0.5 * Sa, Sca));
}

mediump vec3 softLight(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa,
                       in mediump float Da) {
  // safeX = (x <= 0) ? 1 : x;
  mediump float safeDa = Da + step(Da, 0.0);
  
  mediump vec3 below = 2.0 * Sca * Dca + Dca * (Dca / safeDa) * (Sa - 2.0 * Sca) + Sca * (1.0 - Da)
      + Dca * (1.0 - Sa);
  mediump vec3 above = 2.0 * Dca * (Sa - Sca) + sqrt(Dca * Da) * (2.0 * Sca - Sa) +
      Sca * (1.0 - Da) + Dca * (1.0 - Sa);
  
  return mix(below, above, step(0.5 * Sa, Sca));
}

mediump vec3 lighten(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa, in
                     mediump float Da) {
  return max(Sca * Da, Dca * Sa) + Sca * (1.0 - Da) + Dca * (1.0 - Sa);
}

mediump vec3 screen(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa,
                    in mediump float Da) {
  return Sca + Dca - Sca * Dca;
}

mediump vec3 colorBurn(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa,
                       in mediump float Da) {
  mediump float safeDa = Da + step(Da, 0.0);
  mediump vec3 safeSca = Sca + step(Sca, vec3(0.0));
  
  mediump vec3 zero = Sca * (1.0 - Da) + Dca * (1.0 - Sa);
  mediump vec3 nonzero = Sa * Da * (vec3(1.0) - min(vec3(1.0), (1.0 - Dca / safeDa) * Sa / safeSca))
      + Sca * (1.0 - Da) + Dca * (1.0 - Sa);
  
  return mix(zero, nonzero, 1.0 - float(equal(Sca, vec3(0.0))));
}

mediump vec3 overlay(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa,
                     in mediump float Da) {
  mediump vec3 below = 2.0 * Sca * Dca + Sca * (1.0 - Da) + Dca * (1.0 - Sa);
  mediump vec3 above = Sca * (1.0 + Da) + Dca * (1.0 + Sa) - 2.0 * Dca * Sca - Da * Sa;
  
  return mix(below, above, step(0.5 * Da, Dca));
}

void main() {
  const lowp vec3 kColorFilter = vec3(0.299, 0.587, 0.114);
  const lowp float kEpsilon = 0.01;
  
  // Image, its smoothed version and its luminance (for saturation).
  lowp vec4 color = texture2D(sourceTexture, vTexcoord);
  lowp float lum = dot(color.rgb, kColorFilter) + kEpsilon;
  lowp float smoothLum = dot(texture2D(smoothTexture, vTexcoord).rgb, kColorFilter);
  
  // Local contrast: lumiance.
  lowp float newLum = clamp(smoothLum + structure * (lum - smoothLum), 0.0, 1.0);
  
  // Local contrast: restore color.
  color.rgb = (color.rgb / vec3(lum)) * vec3(newLum);
  
  // Add grain and vignette.
  lowp float grain = dot(texture2D(grainTexture, vGrainTexcoord).rgb, grainChannelMixer);
  lowp float vignette = texture2D(vignettingTexture, vTexcoord).r;
  color.rgb = color.rgb + grainAmplitude * (grain - 0.5);
  color.rgb = mix(color.rgb, vignetteColor, vignette * vignettingOpacity);
  
  // Tint.
  mediump vec3 Sca = texture2D(colorGradient, vec2(dot(color.rgb, kColorFilter), 0.0)).rgb *
      colorGradientAlpha;
  mediump vec3 Dca = color.rgb;
  mediump float Sa = colorGradientAlpha;
  mediump float Da = 1.0;
  if (blendMode == kBlendModeNormal) {
    color.rgb = normal(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModeDarken) {
    color.rgb = darken(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModeMultiply) {
    color.rgb = multiply(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModeHardLight) {
    color.rgb = hardLight(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModeSoftLight) {
    color.rgb = softLight(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModeLighten) {
    color.rgb = lighten(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModeScreen) {
    color.rgb = screen(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModeColorBurn) {
    color.rgb = colorBurn(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModeOverlay) {
    color.rgb = overlay(Sca, Dca, Sa, Da);
  }
  
  // Saturation.
  color.rgb = mix(vec3(newLum), color.rgb, saturation);
  
  // Tonality: brightness, contrast, exposure and offset.
  color.r = texture2D(toneLUT, vec2(color.r, 0.0)).r;
  color.g = texture2D(toneLUT, vec2(color.g, 0.0)).r;
  color.b = texture2D(toneLUT, vec2(color.b, 0.0)).r;
  
  gl_FragColor = color;
}
