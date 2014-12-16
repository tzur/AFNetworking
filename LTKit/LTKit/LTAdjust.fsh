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
// Tone and details LUTs.
uniform sampler2D toneLUT;
uniform sampler2D detailsLUT;
// RGB channels hold luminance-to-color mapping, while alpha channel hold luminance-to-luminance
// mapping.
uniform sampler2D colorGradientTexture;
// Details control.
uniform mediump float detailsBoost;
// Color control.
uniform mediump mat4 tonalTransform;
// Black and white points.
uniform mediump float blackPoint;
uniform mediump float whitePoint;

varying highp vec2 vTexcoord;

void main() {
  // Read image and apply tonal transformation that encapsulates hue, tint, temperature and
  // saturation.
  mediump vec4 color = texture2D(sourceTexture, vTexcoord);
  mediump vec4 outputColor = tonalTransform * color;

  // Details, shadows, highlights and fillLight.
  // For positive detailsBoost values, details textures is interpolated with original image. For
  // negative values, a smooth layer is created assuming the following identity:
  // details = smooth + boost * (original - smooth)
  // For CLAHE process that is used to create the details texture, boost = 3.5 is a reasonable
  // value.
  const mediump vec3 kRGBToYPrime = vec3(0.299, 0.587, 0.114);
  mediump float originalLum = dot(color.rgb, kRGBToYPrime);
  mediump float details = texture2D(detailsTexture, vTexcoord).r;
  mediump float lum = texture2D(detailsLUT, vec2(originalLum, 0.0)).r;
  details = texture2D(detailsLUT, vec2(details, 0.0)).r;
  lum = mix(lum, mix(-0.4 * (details - 3.5 * lum), details, step(0.0, detailsBoost)),
                          abs(detailsBoost));

  // Luminance rgb conversion and split tone.
  mediump vec3 colorGradient = texture2D(colorGradientTexture, vec2(lum)).rgb;
  // If originalLum is 0, set it to 1.
  originalLum = originalLum + step(originalLum, 0.0);
  outputColor.rgb = colorGradient * (outputColor.rgb / originalLum);

  // Tone, Levels and Curves.
  outputColor.r = texture2D(toneLUT, vec2(outputColor.r, 0.0)).r;
  outputColor.g = texture2D(toneLUT, vec2(outputColor.g, 0.0)).g;
  outputColor.b = texture2D(toneLUT, vec2(outputColor.b, 0.0)).b;
  outputColor = (outputColor - blackPoint) / (whitePoint - blackPoint);

  gl_FragColor = outputColor;
}
