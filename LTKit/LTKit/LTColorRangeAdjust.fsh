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
// Tonal adjustment.
uniform mediump mat4 tonalTransform;
uniform mediump vec3 maskColor;

varying highp vec2 vTexcoord;

void main() {
  // Compute output color with tonal transformation using cheap linearization.
  mediump vec4 color = texture2D(sourceTexture, vTexcoord);
  mediump vec4 outputColor = sqrt(clamp(tonalTransform * (color * color), 0.0, 1.0));

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
