// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// The goal of this shader is to tonally adjust the image. The adjustments can be categorized into
// the following categories: luminance, levels, color details and split-tone.
// Note: luminance / color separation is done using YIQ color space. But when moving back from YIQ
// to RGB, unchanged luminance is used. Changes in luminance are added using the following:
// newColor = newLum * (oldColor / oldLum)
// This is done in order to avoid coloration of the highlights inherent to YIQ->RGB conversion.

// Source texture and its smoothed versions.
uniform sampler2D sourceTexture;
uniform sampler2D detailsTexture;
// RGB channels hold luminance-to-color mapping, while alpha channel hold luminance-to-luminance
// mapping.
uniform sampler2D colorGradientTexture;

// Tone and details LUTs.
uniform sampler2D toneLUT;
uniform sampler2D detailsLUT;

// Details control.
uniform mediump float detailsBoost;

// Color control.
uniform mediump float saturation;
uniform mediump float temperature;
uniform mediump float tint;

varying highp vec2 vTexcoord;

void main() {
  const mediump vec3 kRGBToYPrime = vec3(0.299, 0.587, 0.114);
  
  const mediump mat3 RGBtoYIQ = mat3(0.299, 0.596, 0.212,
                                     0.587, -0.274, -0.523,
                                     0.114, -0.322, 0.311);
  const mediump mat3 YIQtoRGB = mat3(1.0, 1.0, 1.0,
                                     0.9563, -0.2721, -1.107,
                                     0.621, -0.6474, 1.7046);
  const mediump float kIMax = 0.596;
  const mediump float kQMax = 0.523;
  const mediump float kEps = 0.01;
  
  // Read textures and compute YIQ values.
  mediump vec4 color = texture2D(sourceTexture, vTexcoord);
  mediump float details = texture2D(detailsTexture, vTexcoord).r;
  
  mediump vec3 yiq = RGBtoYIQ * color.rgb;
  mediump float lum = yiq.r;

  // Details, shadows, highlights and fillLight.
  // For positive detailsBoost values, details textures is interpolated with original image. For
  // negative values, a smooth layer is created assuming the following identity:
  // details = smooth + boost * (original - smooth)
  // For CLAHE process that is used to create the details texture, boost = 3.5 is a reasonable
  // value.
  lum = texture2D(detailsLUT, vec2(lum, 0.0)).r;
  details = texture2D(detailsLUT, vec2(details, 0.0)).r;
  lum = mix(lum, mix(-0.4 * (details - 3.5 * lum), details, step(0.0, detailsBoost)),
                          abs(detailsBoost));

  // Color: saturation, temperature and tint.
  yiq.g = clamp((yiq.g + temperature) * saturation, -kIMax, kIMax);
  yiq.b = clamp((yiq.b + tint) * saturation, -kQMax, kQMax);
  mediump vec4 outputColor = vec4(YIQtoRGB * yiq, color.a);

  // Luminance rgb conversion and split tone.
  mediump vec3 colorGradient = texture2D(colorGradientTexture, vec2(lum)).rgb;
  outputColor.rgb = colorGradient * (outputColor.rgb / vec3(yiq.r + 0.004));

  // Tone, Levels and Curves.
  outputColor.r = texture2D(toneLUT, vec2(outputColor.r, 0.0)).r;
  outputColor.g = texture2D(toneLUT, vec2(outputColor.g, 0.0)).g;
  outputColor.b = texture2D(toneLUT, vec2(outputColor.b, 0.0)).b;
  
  gl_FragColor = outputColor;
}
