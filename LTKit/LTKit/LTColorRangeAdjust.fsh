// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// This shader adjusts hue, saturation and luminance of the source image based on hue/luminance
// masks that it constructs.

const int kColorRangeModeImage = 0;
const int kColorRangeModeMask = 1;
const int kColorRangeModeMaskOverlay = 2;

uniform sampler2D sourceTexture;
uniform sampler2D dualMaskTexture;
uniform sampler2D detailsTexture;
// Details control.
uniform mediump float detailsBoost;

uniform int mode;
uniform mediump vec3 rangeColor;
uniform mediump float edge0;
// Tonal adjustment.
uniform mediump mat4 tonalTransform;
uniform mediump vec3 maskColor;

varying highp vec2 vTexcoord;

void main() {
  // Compute output color with tonal transformation using cheap linearization.
  mediump vec4 color = texture2D(sourceTexture, vTexcoord);
  mediump vec4 outputColor = sqrt(clamp(tonalTransform * (color * color), 0.0, 1.0));

  // Update local contrast using CLAHE.
  // For positive detailsBoost values, details textures is interpolated with original image. For
  // negative values, a smooth layer is created assuming the following identity:
  // details = smooth + boost * (original - smooth)
  // For CLAHE process that is used to create the details texture, boost = 3.5 is a reasonable
  // value.
  const mediump vec3 kRGBToYPrime = vec3(0.299, 0.587, 0.114);
  mediump float originalLum = dot(color.rgb, kRGBToYPrime);
  mediump float details = texture2D(detailsTexture, vTexcoord).r;
  details = mix(originalLum, mix(-0.4 * (details - 3.5 * originalLum), details,
                                 step(0.0, detailsBoost)), abs(detailsBoost));
  outputColor.rgb = details * (outputColor.rgb / vec3(originalLum + 0.004));

  // Construct mask and mix with the original image.
  mediump float mask = texture2D(dualMaskTexture, vTexcoord).r;
  mask *= smoothstep(edge0, 0.0, distance(color.rgb, rangeColor));
  outputColor = mix(color, outputColor, mask);

  if (mode == kColorRangeModeImage) {
    gl_FragColor = outputColor;
  } else if (mode == kColorRangeModeMask) {
    gl_FragColor = vec4(vec3(mask), color.a);
  } else if (mode == kColorRangeModeMaskOverlay) {
    gl_FragColor = vec4(mix(color.rgb, maskColor, mask), color.a);
  } else {
    gl_FragColor = color;
  }
}
