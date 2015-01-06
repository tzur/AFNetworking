// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// This shader applies a tilt-shift effect by creating blur and mixing it with the original image
// using dual mask.
// The blur is constructed by mixing the original imagea and two differnt blur levels according to
// the intensity parameter.

uniform sampler2D sourceTexture;
uniform sampler2D fineTexture;
uniform sampler2D mediumTexture;
uniform sampler2D coarseTexture;
uniform sampler2D veryCoarseTexture;
uniform sampler2D dualMaskTexture;
uniform sampler2D userMaskTexture;

uniform mediump float intensity;
uniform bool invertMask;

varying highp vec2 vTexcoord;

void main() {
  lowp vec4 color = texture2D(sourceTexture, vTexcoord);
  lowp vec3 fine = texture2D(fineTexture, vTexcoord).rgb;
  lowp vec3 medium = texture2D(mediumTexture, vTexcoord).rgb;
  lowp vec3 coarse = texture2D(coarseTexture, vTexcoord).rgb;
  lowp vec3 veryCoarse = texture2D(veryCoarseTexture, vTexcoord).rgb;
  
  mediump float dualMask = texture2D(dualMaskTexture, vTexcoord).r;
  dualMask = clamp(dualMask * 2.0, 0.0, 1.0);
  if (!invertMask) {
    dualMask = 1.0 - dualMask;
  }
  mediump float userMask = texture2D(userMaskTexture, vTexcoord).r;
  mediump float alpha = intensity * userMask * dualMask;

  lowp vec3 outputColor;
  if (alpha >= 0.0 && alpha < 0.25) {
    outputColor = mix(color.rgb, fine, alpha / 0.25);
  } else if (alpha >= 0.25 && alpha < 0.5) {
    outputColor = mix(fine, medium, (alpha - 0.25) / 0.25);
  } else if (alpha >= 0.5 && alpha < 0.75) {
    outputColor = mix(medium, coarse, (alpha - 0.5) / 0.25);
  } else {
    outputColor = mix(coarse, veryCoarse, (alpha - 0.75) / 0.25);
  }

  gl_FragColor = vec4(outputColor, color.a);
}
