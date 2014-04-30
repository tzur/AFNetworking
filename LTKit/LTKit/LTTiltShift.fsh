// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// This shader applies a tilt-shift effect by creating blur and mixing it with the original image
// using dual mask.
// The blur is constructed by mixing the original imagea and two differnt blur levels according to
// the intensity parameter.

uniform sampler2D sourceTexture;
uniform sampler2D fineTexture;
uniform sampler2D coarseTexture;
uniform sampler2D dualMaskTexture;

uniform mediump float intensity;

varying highp vec2 vTexcoord;

void main() {
  lowp vec3 color = texture2D(sourceTexture, vTexcoord).rgb;
  lowp vec3 fine = texture2D(fineTexture, vTexcoord).rgb;
  lowp vec3 coarse = texture2D(coarseTexture, vTexcoord).rgb;

  // Splitting point between original-fine and fine-coarse regimes.
  lowp float splittingPoint = 0.4;
  lowp vec3 blur = mix(mix(color, fine, intensity / splittingPoint),
                       mix(fine, coarse, (intensity - splittingPoint) / (1.0 - splittingPoint)),
                       step(splittingPoint, intensity));
  
  lowp float dualMask = texture2D(dualMaskTexture, vTexcoord).r;
  
  lowp vec3 result = mix(blur, color, dualMask);
  
  gl_FragColor = vec4(vec3(result), 1.0);
}
