// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#extension GL_EXT_shader_framebuffer_fetch : require

const int kModePaint = 0;
const int kModeEraseDirect = 1;
const int kModeEraseIndirect = 2;

uniform int mode;

uniform mediump sampler2D sourceTexture;

uniform highp float opacity;
uniform highp float flow;
uniform highp vec4 intensity;

varying highp vec2 vTexcoord;

void main() {
  mediump vec4 previousColor = gl_LastFragData[0];
  highp vec4 newColor = texture2D(sourceTexture, vTexcoord).r * intensity;
  
  if (mode == kModeEraseDirect) {
    // LTRoundBrushModeEraseDirect.
    gl_FragColor =
        clamp(max(previousColor - flow * newColor, 1.0 - opacity), vec4(0.0), previousColor);
  } else if (mode == kModeEraseIndirect) {
    // LTRoundBrushModeEraseIndirect.
    gl_FragColor = clamp(max(previousColor - flow * newColor, -opacity), vec4(-1.0), previousColor);
  } else {
    // Default mode is LTRoundBrushModePaint: regular painting.
    gl_FragColor = clamp(min(previousColor + flow * newColor, opacity), previousColor, vec4(1.0));
  }
}
