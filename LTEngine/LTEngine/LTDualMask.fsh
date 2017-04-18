// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// This shader creates a dual mask.
// See lightricks-research/enlight/DualMask/ for a playground with concepts used by this shader and
// references to distance computation problem.

const int kMaskTypeRadial = 0;
const int kMaskTypeLinear = 1;
const int kMaskTypeDoubleLinear = 2;
const int kMaskConstant = 3;

uniform sampler2D sourceTexture;

uniform mediump vec2 aspectRatioCorrection;

uniform int maskType;
uniform mediump vec2 center;
uniform mediump float shift;
uniform mediump float spread;
uniform mediump float stretchInversed;
uniform mediump vec2 normal;
uniform mediump mat2 rotation;
uniform highp mat3 transform;

uniform bool invert;

varying highp vec2 vTexcoord;

void main() {
  sourceTexture;

  mediump vec3 transformedTexcoord = transform * vec3(vTexcoord, 1.0);
  mediump vec2 coords = (transformedTexcoord.xy / transformedTexcoord.z - center) *
      aspectRatioCorrection;

  mediump float dist;

  // Distance field.
  if (maskType == kMaskTypeRadial) {
    mediump vec2 coordsRotated = rotation * coords;
    dist = length(vec2(coordsRotated.x * stretchInversed, coordsRotated.y));
  } else if (maskType == kMaskTypeLinear) {
    dist = -normal.y * coords.x - normal.x * coords.y;
  } else if (maskType == kMaskTypeDoubleLinear) {
    dist = abs(-normal.y * coords.x - normal.x * coords.y);
  } else if (maskType == kMaskConstant) {
    gl_FragColor = vec4(vec3(1.0 - float(invert)), 1.0);
    return;
  }
  // Mask.
  dist = dist * 2.0 - shift;
  dist = smoothstep(1.0 + spread, 0.0 - spread, dist);

  if (invert) {
    dist = 1.0 - dist;
  }

  gl_FragColor = vec4(vec3(dist), 1.0);
}
