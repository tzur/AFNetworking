// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#extension GL_EXT_shader_framebuffer_fetch : require

const int kModeReshape = 0;
const int kModeResize = 1;
const int kModeUnwarp = 2;

uniform int mode;

uniform mediump sampler2D sourceTexture;
uniform mediump sampler2D maskTexture;

uniform highp vec2 aspectFactor;
uniform highp vec2 center;
uniform highp vec2 direction;
uniform highp float scale;
uniform highp float diameter;
uniform highp float density;
uniform highp float pressure;

varying highp vec2 vTexcoord;

/// Sigma used for generating a gaussian with a falloff which is very close to \c 0 at the edges.
const highp float kGaussianSigma = 0.3;

void main() {
  sourceTexture;
  
  // Multiply the point with the aspect ratio to get accurate euclidean distances based on the real
  // texture dimensions (since we're working with normalized coordinates here).
  highp vec2 lastFrag = gl_LastFragData[0].rg;
  highp vec2 currentPointWithOffset = (vTexcoord + lastFrag) * aspectFactor;
  
  // Calculate the squared distance (normalized by the brush diameter).
  highp vec2 diff = currentPointWithOffset - center;
  highp float normalizedSquaredDistance = dot(diff, diff) / (0.25 * diameter * diameter);

  // Calculate the intensity based on the brush density, pressure, and the distance from the center.
  highp float sigma = density * kGaussianSigma;
  highp float intensity = exp(-normalizedSquaredDistance / (2.0 * sigma * sigma)) * pressure;

  // Perform the actual transformation based on the mode, intensity, and the type-specific paramter.
  highp vec2 delta;
  if (mode == kModeReshape) {
    delta = intensity * direction;
  } else if (mode == kModeResize) {
    intensity *= scale;
    delta = intensity * (currentPointWithOffset - center);
    delta /= aspectFactor;
  } else if (mode == kModeUnwarp) {
    intensity = min(2.0 * intensity, 1.0);
    delta = -intensity * lastFrag;
    gl_FragColor = vec4(lastFrag + delta, 0.0, 1.0);
    return;
  } else {
    delta = vec2(0.0);
  }
  
  // Dampen the transformation by 50% if the target vertex (after the transformation) is inside the
  // mask. Repeat to get more accurate results and avoid a step edge in transformed areas near the
  // boundary of the mask.
  highp float maskTarget = texture2D(maskTexture, vTexcoord + lastFrag + delta).r;
  delta *= 0.5 + 0.5 * maskTarget;
  maskTarget = texture2D(maskTexture, vTexcoord + lastFrag + delta).r;
  delta *= 0.5 + 0.5 * maskTarget;
  maskTarget = texture2D(maskTexture, vTexcoord + lastFrag + delta).r;
  delta *= 0.5 + 0.5 * maskTarget;
  
  // Dampen the transformation if the source vertex (before the transformation) is inside the mask.
  highp float maskSource = texture2D(maskTexture, vTexcoord + lastFrag).r;
  delta *= maskSource;

  gl_FragColor = vec4(lastFrag + delta, 0.0, 1.0);
}
