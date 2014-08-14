// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// This shader applies a duo filter using dual mask.
// See lightricks-research/enlight/Duo/ for a playground with concepts used by this shader.

const int kBlendModeNormal = 0;
const int kBlendModeDarken = 1;
const int kBlendModeMultiply = 2;
const int kBlendModeHardLight = 3;
const int kBlendModeSoftLight = 4;
const int kBlendModeLighten = 5;
const int kBlendModeScreen = 6;
const int kBlendModeColorBurn = 7;
const int kBlendModeOverlay = 8;

uniform sampler2D sourceTexture;
uniform sampler2D dualMaskTexture;

uniform sampler2D blueLUT;
uniform sampler2D redLUT;
uniform int blendMode;
uniform mediump float opacity;

varying highp vec2 vTexcoord;
mediump vec3 normal(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa,
                    in mediump float Da) {
  return Sca + Dca * (1.0 - Sa);
}

mediump vec3 darken(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa,
                    in mediump float Da) {
  return min(Sca * Da, Dca * Sa) + Sca * (1.0 - Da) + Dca * (1.0 - Sa);
}

mediump vec3 multiply(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa,
                      in mediump float Da) {
  return Sca * Dca + Sca * (1.0 - Da) + Dca * (1.0 - Sa);
}

mediump vec3 hardLight(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa,
                       in mediump float Da) {
  mediump vec3 below = 2.0 * Sca * Dca + Sca * (1.0 - Da) + Dca * (1.0 - Sa);
  mediump vec3 above = Sca * (1.0 + Da) + Dca * (1.0 + Sa) - Sa * Da - 2.0 * Sca * Dca;
  
  return mix(below, above, step(0.5 * Sa, Sca));
}

mediump vec3 softLight(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa,
                       in mediump float Da) {
  // safeX = (x <= 0) ? 1 : x;
  mediump float safeDa = Da + step(Da, 0.0);
  
  mediump vec3 below = 2.0 * Sca * Dca + Dca * (Dca / safeDa) * (Sa - 2.0 * Sca) + Sca * (1.0 - Da)
      + Dca * (1.0 - Sa);
  mediump vec3 above = 2.0 * Dca * (Sa - Sca) + sqrt(Dca * Da) * (2.0 * Sca - Sa) +
      Sca * (1.0 - Da) + Dca * (1.0 - Sa);
  
  return mix(below, above, step(0.5 * Sa, Sca));
}

mediump vec3 lighten(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa, in
                     mediump float Da) {
  return max(Sca * Da, Dca * Sa) + Sca * (1.0 - Da) + Dca * (1.0 - Sa);
}

mediump vec3 screen(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa,
                    in mediump float Da) {
  return Sca + Dca - Sca * Dca;
}

mediump vec3 colorBurn(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa,
                       in mediump float Da) {
  mediump float safeDa = Da + step(Da, 0.0);
  mediump vec3 safeSca = Sca + step(Sca, vec3(0.0));
  
  mediump vec3 zero = Sca * (1.0 - Da) + Dca * (1.0 - Sa);
  mediump vec3 nonzero = Sa * Da * (vec3(1.0) - min(vec3(1.0), (1.0 - Dca / safeDa) * Sa / safeSca))
      + Sca * (1.0 - Da) + Dca * (1.0 - Sa);
  
  return mix(zero, nonzero, 1.0 - float(equal(Sca, vec3(0.0))));
}

mediump vec3 overlay(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa,
                     in mediump float Da) {
  mediump vec3 below = 2.0 * Sca * Dca + Sca * (1.0 - Da) + Dca * (1.0 - Sa);
  mediump vec3 above = Sca * (1.0 + Da) + Dca * (1.0 + Sa) - 2.0 * Dca * Sca - Da * Sa;
  
  return mix(below, above, step(0.5 * Da, Dca));
}

void main() {
  // Default NTSC weights for color->luminance conversion.
  const lowp vec3 kColorFilter = vec3(0.299, 0.587, 0.114);
  
  lowp vec4 color = texture2D(sourceTexture, vTexcoord);
  lowp float lum = dot(color.rgb, kColorFilter);
  
  lowp float dualMask = texture2D(dualMaskTexture, vTexcoord).r;
  
  lowp vec4 blueColor = texture2D(blueLUT, vec2(lum, 0.0));
  lowp vec4 redColor = texture2D(redLUT, vec2(lum, 0.0));
  
  mediump float Sa0 = dualMask * blueColor.a * opacity;
  mediump float Sa1 = (1.0 - dualMask) * redColor.a * opacity;
  mediump vec3 Sca0 = blueColor.rgb * Sa0;
  mediump vec3 Sca1 = redColor.rgb * Sa1;
  mediump float Da = 1.0;
  mediump vec3 outputColor;
  
  if (blendMode == kBlendModeNormal) {
    outputColor = normal(Sca0, color.rgb, Sa0, Da);
    outputColor = normal(Sca1, outputColor, Sa1, Da);
  } else if (blendMode == kBlendModeDarken) {
    outputColor = darken(Sca0, color.rgb, Sa0, Da);
    outputColor = darken(Sca1, outputColor, Sa1, Da);
  } else if (blendMode == kBlendModeMultiply) {
    outputColor = multiply(Sca0, color.rgb, Sa0, Da);
    outputColor = multiply(Sca1, outputColor, Sa1, Da);
  } else if (blendMode == kBlendModeHardLight) {
    outputColor = hardLight(Sca0, color.rgb, Sa0, Da);
    outputColor = hardLight(Sca1, outputColor, Sa1, Da);
  } else if (blendMode == kBlendModeSoftLight) {
    outputColor = softLight(Sca0, color.rgb, Sa0, Da);
    outputColor = softLight(Sca1, outputColor, Sa1, Da);
  } else if (blendMode == kBlendModeLighten) {
    outputColor = lighten(Sca0, color.rgb, Sa0, Da);
    outputColor = lighten(Sca1, outputColor, Sa1, Da);
  } else if (blendMode == kBlendModeScreen) {
    outputColor = screen(Sca0, color.rgb, Sa0, Da);
    outputColor = screen(Sca1, outputColor, Sa1, Da);
  } else if (blendMode == kBlendModeColorBurn) {
    outputColor = colorBurn(Sca0, color.rgb, Sa0, Da);
    outputColor = colorBurn(Sca1, outputColor, Sa1, Da);
  } else if (blendMode == kBlendModeOverlay) {
    outputColor = overlay(Sca0, color.rgb, Sa0, Da);
    outputColor = overlay(Sca1, outputColor, Sa1, Da);
  }
  
  gl_FragColor = vec4(outputColor, color.a);
}
