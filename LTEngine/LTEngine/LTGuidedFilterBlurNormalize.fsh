// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

#extension GL_EXT_shader_framebuffer_fetch : require

uniform highp sampler2D sourceTexture;
uniform highp sampler2D normalizationMask;
uniform bool useExternalMask;
uniform bool clampMaximum;

varying highp vec2 vTexcoord;

void main() {
  sourceTexture;

  highp vec4 color = gl_LastFragData[0];
  highp float normalizationValue;
  if (useExternalMask) {
    normalizationValue = texture2D(normalizationMask, vTexcoord).r;
  } else {
    normalizationValue = color.a;
  }
  highp float safeNormalizationValue = normalizationValue + step(normalizationValue, 0.0);
  color.rgb = color.rgb / safeNormalizationValue;
  if (clampMaximum) {
    color.rgb = min(vec3(1.0), color.rgb);
  }
  gl_FragColor = vec4(color.rgb, 1.0);
}
