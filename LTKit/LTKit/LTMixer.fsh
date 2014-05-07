// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#extension GL_EXT_shader_framebuffer_fetch : require

const int kBlendModeNormal = 0;
const int kBlendModeDarken = 1;
const int kBlendModeMultiply = 2;
const int kBlendModeHardLight = 3;
const int kBlendModeSoftLight = 4;

uniform lowp sampler2D sourceTexture;
uniform mediump sampler2D maskTexture;

uniform int blendMode;

varying highp vec2 vFrontTexcoord;
varying highp vec2 vMaskTexcoord;

void main() {
  mediump vec4 back = gl_LastFragData[0];
  lowp vec4 front = texture2D(sourceTexture, vFrontTexcoord);
  mediump vec4 mask = texture2D(maskTexture, vMaskTexcoord);

  // Calculate new front, including mask alpha value.
  front = front * mask.r;

  // Define variables as they appear in SVG spec. See http://www.w3.org/TR/SVGCompositing/.
  mediump vec3 Sca = front.rgb;
  mediump vec3 Dca = back.rgb;
  mediump float Sa = front.a;
  mediump float Da = back.a;

  if (blendMode == kBlendModeNormal) {
    gl_FragColor.rgb = Sca + Dca * (1.0 - Sa);
    gl_FragColor.a = Sa + Da - Sa * Da;
  } else if (blendMode == kBlendModeDarken) {
    gl_FragColor.rgb = min(Sca * Da, Dca * Sa) + Sca * (1.0 - Da) + Dca * (1.0 - Sa);
    gl_FragColor.a = Sa + Da - Sa * Da;
  } else if (blendMode == kBlendModeMultiply) {
    gl_FragColor.rgb = Sca * Dca + Sca * (1.0 - Da) + Dca * (1.0 - Sa);
    gl_FragColor.a = Sa + Da - Sa * Da;
  } else if (blendMode == kBlendModeHardLight) {
    highp vec3 below = 2.0 * Sca * Dca + Sca * (1.0 - Da) + Dca * (1.0 - Sa);
    highp vec3 above = Sca * (1.0 + Da) + Dca * (1.0 + Sa) - Sa * Da - 2.0 * Sca * Dca;
    gl_FragColor.rgb = mix(below, above, step(0.5 * Sa, Sca.rgb));
    gl_FragColor.a = Sa + Da - Sa * Da;
  } else {
    gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
  }
}
