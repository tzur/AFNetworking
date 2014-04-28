// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// This shader creates a dual mask.
// See lightricks-research/enlight/DualMask/ for a playground with concepts used by this shader and
// references to distance computation problem.

const int kMaskTypeRadial = 0;
const int kMaskTypeLinear = 1;
const int kMaskTypeDoubleLinear = 2;

uniform sampler2D sourceTexture;

uniform mediump vec2 aspectRatioCorrection;

uniform int maskType;
uniform mediump vec2 center;
uniform mediump float shift;
uniform mediump float spread;
uniform mediump vec2 normal;

varying highp vec2 vTexcoord;

void main() {
  sourceTexture;
  
  mediump vec2 coords = (vTexcoord - center) * aspectRatioCorrection;
  mediump float dist;
  
  // Distance field.
  if (maskType == kMaskTypeRadial) {
    dist = length(coords);
  } else if (maskType == kMaskTypeLinear) {
    dist = -normal.y * coords.x - normal.x * coords.y;
  } else if (maskType == kMaskTypeDoubleLinear) {
    dist = abs(-normal.y * coords.x - normal.x * coords.y);
  }
  // Mask.
  dist = max(0.0, dist * 2.0 - shift);
  dist = smoothstep(1.0 - spread, 0.0 + spread, dist);
  
  gl_FragColor = vec4(vec3(dist), 1.0);
}
