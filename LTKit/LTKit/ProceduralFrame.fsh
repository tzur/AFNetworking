// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

uniform sampler2D sourceTexture;
uniform sampler2D noiseTexture;

// Wide frame settings.
uniform highp float edge0;
uniform highp float edge1;
uniform highp float corner;
uniform highp float transitionExponent;
uniform highp vec3 noiseChannelMixer;
uniform highp float noiseAmplitude;
// Shifts and normalizes the distance field, in order to create the same width and spread in both
// dimensions.
uniform highp vec2 distanceShift;

varying highp vec2 vTexcoord;

void main() {
  sourceTexture;
  
  noiseChannelMixer;
  
  highp vec2 center = abs(vTexcoord - 0.5) * 2.0; // [0:1] to [-1:1].
  // Aspect ratio correction.
  center = clamp(center - distanceShift, 0.0, 1.0) / (1.0 - distanceShift);
  
  highp float dist;
  if (corner == 0.0) {
    dist = max(center.x, center.y);
  } else {
    center = pow(center.xy, vec2(corner));
    dist = center.x + center.y;
  }
  // Create transition region and clamp everywhere else.
  dist = smoothstep(edge1, edge0, dist);
  dist = pow(dist, transitionExponent);
  
  // Read noise and make it zero mean.
  highp float noise = texture2D(noiseTexture, vTexcoord).r - 0.5;
  noise *= noiseAmplitude;
  
  highp float frame;
  highp float contrastScalingFactor = 1.0 - 2.0 * abs(dist - 0.5);
  frame = mix(dist + noise * contrastScalingFactor, dist, step(1.0, dist));
  frame = mix(frame, 0.0, step(dist, 0.0));
  
  gl_FragColor = vec4(vec3(frame), 0.5);
}
