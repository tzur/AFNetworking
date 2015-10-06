// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#extension GL_EXT_shader_framebuffer_fetch : require

const int kModePaint = 0;
const int kModeEraseDirect = 1;
const int kModeEraseIndirect = 2;
const int kModeBlend = 3;

uniform int mode;

uniform mediump sampler2D sourceTexture;

uniform highp float opacity;
uniform highp float flow;
uniform highp vec4 intensity;

varying highp vec2 vTexcoord;

// Blend the source and the target according to the normal alpha blending formula:
// http://en.wikipedia.org/wiki/Alpha_compositing#Alpha_blending
void normalNonPremultiplied(in highp vec4 src, in highp vec4 dst) {
  highp float a = src.a + dst.a - src.a * dst.a;
  highp vec3 rgb = src.rgb * src.a + (1.0 - src.a) * dst.a * dst.rgb;

  // If the result alpha is 0, the result rgb should be 0 as well.
  // safeA = (a <= 0) ? 1 : a;
  // gl_FragColor = (a <= 0) ? 0 : vec4(rgb / a, a);
  highp float safeA = a + (step(a, 0.0));
  gl_FragColor = clamp((1.0 - step(a, 0.0)) * vec4(rgb / safeA, a), 0.0, 1.0);
}

void main() {
  mediump vec4 previousColor = gl_LastFragData[0];
  highp float brush = texture2D(sourceTexture, vTexcoord).r;

  if (mode == kModeEraseDirect) {
    highp vec4 newColor = brush * intensity;
    gl_FragColor =
        clamp(max(previousColor - flow * newColor, 1.0 - opacity), vec4(0.0), previousColor);
  } else if (mode == kModeEraseIndirect) {
    highp vec4 newColor = brush * intensity;
    gl_FragColor = clamp(max(previousColor - flow * newColor, -opacity), vec4(-1.0), previousColor);
  } else if (mode == kModeBlend) {
    // Apply the flow factor on the alpha channel, and use the opacity as an upper bound.
    highp vec4 newColor = intensity;
    newColor.a = min(newColor.a * flow * brush, opacity);
    normalNonPremultiplied(newColor, previousColor);
  } else {
    // Default mode is LTRoundBrushModePaint: regular painting.
    highp vec4 newColor = brush * intensity;
    gl_FragColor = clamp(min(previousColor + flow * newColor, opacity), previousColor, vec4(1.0));
  }
}
