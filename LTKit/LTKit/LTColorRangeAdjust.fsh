// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// This shader adjusts hue, saturation and luminance of the source image based on hue/luminance
// masks that it constructs.

const int kColorRangeModeImage = 0;
const int kColorRangeModeMask = 1;
const int kColorRangeModeMaskOverlay = 2;

uniform sampler2D sourceTexture;
uniform sampler2D dualMaskTexture;

uniform int mode;
uniform mediump vec3 rangeColor;
uniform mediump float edge0;
uniform mediump float saturation;
uniform mediump float exposure;
uniform mediump float contrast;
uniform mediump mat2 rotation;

varying highp vec2 vTexcoord;

void main() {
  mediump vec4 color = texture2D(sourceTexture, vTexcoord);
  mediump float mask = texture2D(dualMaskTexture, vTexcoord).r;

  // Convert to NRGB.
  mediump float sum = color.r + color.g + color.b;
  const mediump float kEpsilon = 0.075;
  mediump vec3 nrgb = color.rgb / (sum + kEpsilon);
  
  // Construct mask.
  mask *= smoothstep(edge0, 0.0, distance(color.rgb, rangeColor));

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
  const mediump float kPivot = 0.45;
  outputColor = mix(kPivot + contrast * (lum * exposure - kPivot),
                    kPivot + contrast * (outputColor * exposure - kPivot), saturation);
  outputColor = mix(color.rgb, outputColor, mask);
  
  if (mode == kColorRangeModeImage) {
    gl_FragColor = vec4(outputColor, color.a);
  } else if (mode == kColorRangeModeMask) {
    gl_FragColor = vec4(vec3(mask), color.a);
  } else if (mode == kColorRangeModeMaskOverlay) {
    /// Mask at full intensity is rendered with a bluish color.
    const mediump vec3 kMaskColor = vec3(0.2969, 0.5, 0.8984);
    gl_FragColor = vec4(mix(color.rgb, kMaskColor, mask), color.a);
  } else {
    gl_FragColor = color;
  }
}
