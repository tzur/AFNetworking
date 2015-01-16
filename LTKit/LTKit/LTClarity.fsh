// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// This shader applies a clarity effect, by manipulating dtails at fine, medium and coarse scales.
// Saturation control is provided in order to compensate for perceived colorfulness changes that
// result from local contrast boosting.

uniform sampler2D sourceTexture;
uniform sampler2D downsampledTexture;
uniform sampler2D bilateralTexture;
uniform sampler2D eawTexture;

uniform mediump float sharpen;
uniform mediump float fineContrast;
uniform mediump float mediumContrast;
uniform mediump float flattenA;
uniform mediump float flattenBlend;
uniform mediump float gain;
uniform mediump float saturation;

varying highp vec2 vTexcoord;

mediump float squareSigmoid(in mediump float x, in mediump float a, in mediump float b) {
  return a * x / sqrt(b + x * x);
}

mediump vec3 squareSigmoid(in mediump vec3 x, in mediump float a, in mediump float b) {
  return a * x / sqrt(b + x * x);
}

mediump float addFlatten(in mediump float x) {
  return mix(x, squareSigmoid(x, flattenA, flattenA), flattenBlend);
}

mediump vec3 addGain(in mediump vec3 x) {
  return mix(x, squareSigmoid(x - 0.25, 1.0, 0.1) + 0.25, gain);
}

void main() {
  mediump vec4 color = texture2D(sourceTexture, vTexcoord);
  mediump vec4 veryFineColor = texture2D(downsampledTexture, vTexcoord);
  mediump vec4 fineColor = texture2D(bilateralTexture, vTexcoord);
  mediump float mediumLum = texture2D(eawTexture, vTexcoord).r;

  const mediump vec3 kRGBToYPrime = vec3(0.299, 0.587, 0.114);
  mediump float fineLum = dot(fineColor.rgb, kRGBToYPrime);

  // Manipulate coarse levels.
  // Gamma is added to treat underexposed parts better. Log function is typically too harsh for low
  // dynamic range images and thus avoided.
  const mediump float kGamma = 0.35;
  mediump float kBase = 0.7562; // == pow(0.45, kGamma);
  mediumLum = pow(mediumLum, kGamma);
  mediump float newLum = kBase + addFlatten(mediumLum - kBase) + mediumContrast *
      (pow(fineLum, kGamma) - mediumLum);
  // Remove gamma.
  newLum = pow(newLum, 1.0 / kGamma);
  // Restore color.
  mediump vec3 newFineColor = newLum * (fineColor.rgb / (fineLum + step(fineLum, 0.0)));

  // Manipulate fine levels.
  mediump vec4 outputColor = vec4(addGain(newFineColor), color.a);
  outputColor += sharpen * (color - veryFineColor) + fineContrast * (veryFineColor - fineColor);

  // Saturation.
  outputColor.rgb = mix(vec3(dot(outputColor.rgb, kRGBToYPrime)), outputColor.rgb, saturation);
  outputColor = clamp(outputColor, 0.0, 1.0);

  gl_FragColor = outputColor;
}
