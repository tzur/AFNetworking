// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// This shader adjusts hue, saturation and luminance of the source image based on hue/luminance
// masks that it constructs.

const int kColorRangeModeImage = 0;
const int kColorRangeModeMask = 1;
const int kColorRangeModeMaskOverlay = 2;

uniform sampler2D sourceTexture;

uniform int mode;
uniform mediump vec3 rangeColor;
uniform mediump float edge0;
uniform mediump float edge1;
uniform mediump float saturation;
uniform mediump float luminance;
uniform mediump mat2 rotation;

varying highp vec2 vTexcoord;

void main() {
  mediump vec4 color = texture2D(sourceTexture, vTexcoord);
  
  // Convert to NRGB.
  mediump float sum = color.r + color.g + color.b;
  const mediump float kEpsilon = 0.075;
  mediump vec3 nrgb = color.rgb / (sum + kEpsilon);
  
  // Construct mask.
  mediump float mask = smoothstep(edge0, edge1, distance(color.rgb, rangeColor));
  
  // Compute luminance.
  const mediump vec3 kRGBToYPrime = vec3(0.299, 0.587, 0.114);
  mediump vec3 lum = vec3(dot(color.rgb, kRGBToYPrime));
  
  // Shift hue: rotate around grey and translate back.
  nrgb = nrgb - 0.3333;
  mediump vec3 outputColor;
  outputColor.rg = (rotation * nrgb.rg + 0.3333) * (sum + kEpsilon);
  outputColor.b = sum - (outputColor.r + outputColor.g);
  outputColor = clamp(outputColor, 0.0, 1.0);
  
  // Change luminance and saturation.
  outputColor = mix(lum + luminance, outputColor + luminance, saturation);
  outputColor = mix(color.rgb, outputColor, mask);
  
  if (mode == kColorRangeModeImage) {
    gl_FragColor = vec4(outputColor, color.a);
  } else if (mode == kColorRangeModeMask) {
    gl_FragColor = vec4(vec3(mask), color.a);
  } else if (mode == kColorRangeModeMaskOverlay) {
    mask = clamp((max(mask, 0.2) - 0.2) * 2.0 + 0.2, 0.0, 1.0);
    gl_FragColor = vec4(outputColor * mask, mask);
  } else {
    gl_FragColor = color;
  }
}
