// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// This shader adjusts hue, saturation and luminance of the source image based on hue/luminance
// masks that it constructs.

#extension GL_EXT_shader_framebuffer_fetch : require

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

uniform bool disableRangeAttenuation;

varying highp vec2 vTexcoord;

void normal(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa, in mediump float Da) {
  gl_FragColor.rgb = Sca + Dca * (1.0 - Sa);
  gl_FragColor.a = Sa + Da - Sa * Da;
}

void main() {
  // Compute output color with tonal transformation using cheap linearization.
  mediump vec4 color = texture2D(sourceTexture, vTexcoord);

  // Construct mask and mix with the original image.
  mediump float mask = texture2D(dualMaskTexture, vTexcoord).r;
  if (!disableRangeAttenuation) {
    mask *= smoothstep(edge0, 0.0, distance(sqrt(color.rgb), rangeColor));
  }

  if (mode == kColorRangeModeImage) {
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
    // If originalLum is 0, set it to 1.
    originalLum = originalLum + step(originalLum, 0.0);
    outputColor.rgb = details * (outputColor.rgb / originalLum);
    gl_FragColor = mix(color, outputColor, mask);
  } else if (mode == kColorRangeModeMask) {
    gl_FragColor = vec4(vec3(mask), color.a);
  } else if (mode == kColorRangeModeMaskOverlay) {
    normal(maskColor * mask, gl_LastFragData[0].rgb, mask, gl_LastFragData[0].a);
  } else {
    gl_FragColor = color;
  }
}
