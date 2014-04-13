// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

uniform sampler2D sourceTexture;
uniform sampler2D smoothTexture;
uniform sampler2D grainTexture;
uniform sampler2D vignettingTexture;

// Tone and tinting (colorizing) gradients.
uniform sampler2D toneLUT;
uniform sampler2D colorGradient;

varying highp vec2 vTexcoord;
varying highp vec2 vGrainTexcoord;

uniform mediump float colorGradientAlpha;
uniform mediump float structure;
uniform mediump float saturation;

uniform mediump float vignettingOpacity;
uniform mediump vec3 vignetteColor;
uniform mediump vec3 grainChannelMixer;
uniform mediump float grainAmplitude;

void main() {
  const lowp vec3 kColorFilter = vec3(0.299, 0.587, 0.114);
  const lowp float kEpsilon = 0.01;
  
  // Image, its smoothed version and its luminance (for saturation).
  lowp vec4 color = texture2D(sourceTexture, vTexcoord);
  lowp float lum = dot(color.rgb, kColorFilter) + kEpsilon;
  lowp float smoothLum = dot(texture2D(smoothTexture, vTexcoord).rgb, kColorFilter);
  
  // Local contrast: lumiance.
  lowp float newLum = clamp(smoothLum + structure * (lum - smoothLum), 0.0, 1.0);
  
  // Local contrast: from luminance to color.
  color.rgb = (color.rgb / vec3(lum)) * vec3(newLum);
  
  // Tint.
  lowp vec3 tintedLum = texture2D(colorGradient, vec2(newLum, 0.0)).rgb;
  color.rgb = mix(color.rgb, tintedLum, colorGradientAlpha);
  
  // Saturation.
  color.rgb = mix(vec3(newLum), color.rgb, saturation);
  
  // Tonality: brightness, contrast, exposure and offset.
  color.r = texture2D(toneLUT, vec2(color.r, 0.0)).r;
  color.g = texture2D(toneLUT, vec2(color.g, 0.0)).r;
  color.b = texture2D(toneLUT, vec2(color.b, 0.0)).r;
  
  // Add grain and vignette.
  lowp float grain = dot(texture2D(grainTexture, vGrainTexcoord).rgb, grainChannelMixer);
  lowp float vignette = texture2D(vignettingTexture, vTexcoord).r;
  color.rgb = color.rgb + grainAmplitude * (grain - 0.5);
  color.rgb = mix(color.rgb, vignetteColor, vignette * vignettingOpacity);
  
  gl_FragColor = color;
}
