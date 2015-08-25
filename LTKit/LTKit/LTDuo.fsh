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
const int kBlendModePlusLighter = 9;
const int kBlendModePlusDarker = 10;

uniform sampler2D sourceTexture;
uniform sampler2D dualMaskTexture;

uniform mediump vec4 blueColor;
uniform mediump vec4 redColor;
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
  mediump vec3 stepSca = step(Sca, vec3(0.0));
  mediump vec3 safeSca = Sca + stepSca;
  
  mediump vec3 zero = Sca * (1.0 - Da) + Dca * (1.0 - Sa);
  mediump vec3 nonzero = Sa * Da * (vec3(1.0) - min(vec3(1.0), (1.0 - Dca / safeDa) * Sa / safeSca))
      + Sca * (1.0 - Da) + Dca * (1.0 - Sa);
  
  return mix(zero, nonzero, 1.0 - stepSca);
}

mediump vec3 overlay(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa,
                     in mediump float Da) {
  mediump vec3 below = 2.0 * Sca * Dca + Sca * (1.0 - Da) + Dca * (1.0 - Sa);
  mediump vec3 above = Sca * (1.0 + Da) + Dca * (1.0 + Sa) - 2.0 * Dca * Sca - Da * Sa;
  
  return mix(below, above, step(0.5 * Da, Dca));
}

mediump vec3 plusLighter(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa,
                         in mediump float Da) {
  return Sca + Dca;
}

mediump vec3 plusDarker(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa,
                        in mediump float Da) {
  return Sca + Dca - 1.0;
}

void main() {
  mediump vec4 color = texture2D(sourceTexture, vTexcoord);
  mediump float mask = texture2D(dualMaskTexture, vTexcoord).r;
  mediump vec3 mixedColor = mix(blueColor.rgb, redColor.rgb, mask);
  mediump float mixedAlpha = mix(blueColor.a, redColor.a, mask);
  
  mediump float Sa = mixedAlpha * opacity;
  mediump float Da = color.a;
  
  mediump vec3 Sca = mixedColor * Sa;
  mediump vec3 Dca = color.rgb * Da;

  mediump vec3 outputColor;
  
  if (blendMode == kBlendModeNormal) {
    outputColor = normal(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModeDarken) {
    outputColor = darken(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModeMultiply) {
    outputColor = multiply(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModeHardLight) {
    outputColor = hardLight(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModeSoftLight) {
    outputColor = softLight(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModeLighten) {
    outputColor = lighten(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModeScreen) {
    outputColor = screen(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModeColorBurn) {
    outputColor = colorBurn(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModeOverlay) {
    outputColor = overlay(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModePlusLighter) {
    outputColor = plusLighter(Sca, Dca, Sa, Da);
  } else if (blendMode == kBlendModePlusDarker) {
    outputColor = plusDarker(Sca, Dca, Sa, Da);
  }

  gl_FragColor = vec4(outputColor, color.a);
}
