// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#extension GL_EXT_shader_framebuffer_fetch : require

const int kBlendModeNormal = 0;
const int kBlendModeDarken = 1;
const int kBlendModeMultiply = 2;
const int kBlendModeHardLight = 3;
const int kBlendModeSoftLight = 4;
const int kBlendModeLighten = 5;
const int kBlendModeScreen = 6;
const int kBlendModeColorBurn = 7;
const int kBlendModeOverlay = 8;
const int kBlendModePlusLighter = 9;
const int kBlendModePlusDarker = 10;

uniform lowp sampler2D sourceTexture;
uniform mediump sampler2D maskTexture;

uniform int blendMode;
uniform mediump float opacity;

varying highp vec2 vFrontTexcoord;
varying highp vec2 vMaskTexcoord;

void normal(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa, in mediump float Da) {
  gl_FragColor.rgb = Sca + Dca * (1.0 - Sa);
  gl_FragColor.a = Sa + Da - Sa * Da;
}

void darken(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa, in mediump float Da) {
  gl_FragColor.rgb = min(Sca * Da, Dca * Sa) + Sca * (1.0 - Da) + Dca * (1.0 - Sa);
  gl_FragColor.a = Sa + Da - Sa * Da;
}

void multiply(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa, in mediump float Da) {
  gl_FragColor.rgb = Sca * Dca + Sca * (1.0 - Da) + Dca * (1.0 - Sa);
  gl_FragColor.a = Sa + Da - Sa * Da;
}

void hardLight(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa, in mediump float Da) {
  mediump vec3 below = 2.0 * Sca * Dca + Sca * (1.0 - Da) + Dca * (1.0 - Sa);
  mediump vec3 above = Sca * (1.0 + Da) + Dca * (1.0 + Sa) - Sa * Da - 2.0 * Sca * Dca;

  gl_FragColor.rgb = mix(below, above, step(0.5 * Sa, Sca));
  gl_FragColor.a = Sa + Da - Sa * Da;
}

void softLight(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa, in mediump float Da) {
  // safeX = (x <= 0) ? 1 : x;
  mediump float safeDa = Da + step(Da, 0.0);

  mediump vec3 below = 2.0 * Sca * Dca + Dca * (Dca / safeDa) * (Sa - 2.0 * Sca) + Sca * (1.0 - Da)
      + Dca * (1.0 - Sa);
  mediump vec3 above = 2.0 * Dca * (Sa - Sca) + sqrt(Dca * Da) * (2.0 * Sca - Sa) +
      Sca * (1.0 - Da) + Dca * (1.0 - Sa);

  gl_FragColor.rgb = mix(below, above, step(0.5 * Sa, Sca));
  gl_FragColor.a = Sa + Da - Sa * Da;
}

void lighten(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa, in mediump float Da) {
  gl_FragColor.rgb = max(Sca * Da, Dca * Sa) + Sca * (1.0 - Da) + Dca * (1.0 - Sa);
  gl_FragColor.a = Sa + Da - Sa * Da;
}

void screen(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa, in mediump float Da) {
  gl_FragColor.rgb = Sca + Dca - Sca * Dca;
  gl_FragColor.a = Sa + Da - Sa * Da;
}

void colorBurn(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa, in mediump float Da) {
  // safeX = (x <= 0) ? 1 : x;
  mediump float safeDa = Da + step(Da, 0.0);
  mediump vec3 safeSca = Sca + step(Sca, vec3(0.0));

  mediump vec3 zero = Sca * (1.0 - Da) + Dca * (1.0 - Sa);
  mediump vec3 nonzero = Sa * Da * (vec3(1.0) - min(vec3(1.0), (1.0 - Dca / safeDa) * Sa / safeSca))
      + Sca * (1.0 - Da) + Dca * (1.0 - Sa);

  gl_FragColor.rgb = mix(zero, nonzero, 1.0 - float(equal(Sca, vec3(0.0))));
  gl_FragColor.a = Sa + Da - Sa * Da;
}

void overlay(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa, in mediump float Da) {
  mediump vec3 below = 2.0 * Sca * Dca + Sca * (1.0 - Da) + Dca * (1.0 - Sa);
  mediump vec3 above = Sca * (1.0 + Da) + Dca * (1.0 + Sa) - 2.0 * Dca * Sca - Da * Sa;

  gl_FragColor.rgb = mix(below, above, step(0.5 * Da, Dca));
  gl_FragColor.a = Sa + Da - Sa * Da;
}

void plusLighter(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa,
                 in mediump float Da) {
  gl_FragColor.rgb = Sca + Dca;
  gl_FragColor.a = Sa + Da;
}

void plusDarker(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa,
                in mediump float Da) {
  gl_FragColor.rgb = 1.0 - ((1.0 - Sca) + (1.0 - Dca));
  // TODO:(yaron) not sure about this. It's not documented anywhere, and in the SVG.
  gl_FragColor.a = Sa + Da;
}

void main() {
  mediump vec4 back = gl_LastFragData[0];
  mediump vec4 front = texture2D(sourceTexture, vFrontTexcoord);
  mediump vec4 mask = texture2D(maskTexture, vMaskTexcoord);

  // Calculate new front, including mask alpha value and opacity.
  front = front * mask.r * opacity;

  // Define variables as they appear in SVG spec. See http://www.w3.org/TR/SVGCompositing/.
  mediump vec3 Sca = front.rgb;
  mediump vec3 Dca = back.rgb;
  mediump float Sa = front.a;
  mediump float Da = back.a;

  if (blendMode == kBlendModeNormal) {
    normal(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModeDarken) {
    darken(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModeMultiply) {
    multiply(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModeHardLight) {
    hardLight(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModeSoftLight) {
    softLight(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModeLighten) {
    lighten(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModeScreen) {
    screen(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModeColorBurn) {
    colorBurn(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModeOverlay) {
    overlay(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModePlusLighter) {
    plusLighter(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModePlusDarker) {
    plusDarker(Sca, Dca, Sa, Da);
  } else {
    gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
  }
}
