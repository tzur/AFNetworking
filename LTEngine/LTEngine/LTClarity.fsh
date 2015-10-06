// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// This shader applies a clarity effect, by manipulating dtails at fine, medium and coarse scales.
// Saturation control is provided in order to compensate for perceived colorfulness changes that
// result from local contrast boosting.

uniform sampler2D sourceTexture;
uniform sampler2D downsampledTexture;
uniform sampler2D bilateralTexture;
uniform sampler2D smoothTexture;

uniform mediump float sharpen;
uniform mediump float fineContrast;
uniform mediump float mediumContrast;
uniform mediump float flattenA;
uniform mediump float flattenBlend;
uniform mediump float gain;
uniform mediump float saturation;
uniform mediump float blackPoint;

varying highp vec2 vTexcoord;

mediump float squareSigmoid(in mediump float x, in mediump float a, in mediump float b) {
  return a * x / sqrt(b + x * x);
}

mediump vec3 squareSigmoid(in mediump vec3 x, in mediump float a, in mediump float b) {
  return a * x / sqrt(b + x * x);
}

mediump vec3 addFlatten(in mediump vec3 x) {
  return mix(x, squareSigmoid(x, flattenA, flattenA), flattenBlend);
}

mediump vec3 addGain(in mediump vec3 x) {
  return mix(x, squareSigmoid(x - 0.25, 1.0, 0.1) + 0.25, gain);
}

void main() {
  mediump vec4 color = texture2D(sourceTexture, vTexcoord);
  mediump vec4 veryFineColor = texture2D(downsampledTexture, vTexcoord);
  mediump vec4 fineColor = texture2D(bilateralTexture, vTexcoord);
  mediump vec3 mediumColor = texture2D(smoothTexture, vTexcoord).rgb;

  const mediump vec3 kRGBToYPrime = vec3(0.299, 0.587, 0.114);

  // Manipulate coarse levels.
  // Gamma is added to treat underexposed parts better. Log function is typically too harsh for low
  // dynamic range images and thus avoided.
  const mediump vec3 kGamma = vec3(0.35);
  mediump float kBase = 0.7562; // == pow(0.45, kGamma);
  mediumColor = pow(mediumColor, kGamma);
  mediump vec3 newFineColor = kBase + addFlatten(mediumColor - kBase) + mediumContrast *
      (pow(fineColor.rgb, kGamma) - mediumColor);

  // Remove gamma.
  newFineColor = pow(newFineColor, 1.0 / kGamma);

  // Manipulate fine levels.
  mediump vec4 outputColor = vec4(addGain(newFineColor), color.a);
  outputColor += sharpen * (color - veryFineColor) + fineContrast * (veryFineColor - fineColor);

  // Saturation.
  outputColor.rgb = mix(vec3(dot(outputColor.rgb, kRGBToYPrime)), outputColor.rgb, saturation);
  outputColor = (outputColor - blackPoint) / (1.0 - blackPoint);
  outputColor = clamp(outputColor, 0.0, 1.0);

  gl_FragColor = outputColor;
}
