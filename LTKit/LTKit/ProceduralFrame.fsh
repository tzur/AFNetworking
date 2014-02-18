// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// This shader creates a procedural frame by manipulating the distance field and adding noise
// in the transition region, between the solidly shaded foreground and completely transparent
// background. See lightricks-research/enlight/ProceduralFrames/ for a playground with the concepts
// used by this shader.

uniform sampler2D sourceTexture;
uniform sampler2D noiseTexture;

// Wide frame settings.
uniform highp float edge0;
uniform highp float edge1;
uniform highp float corner;
uniform highp float transitionExponent;
uniform highp float noiseAmplitude;
uniform highp vec3 noiseChannelMixer;
uniform highp vec3 color;
// Shifts and normalizes the distance field, in order to create the same width and spread in both
// dimensions.
uniform highp vec2 distanceShift;

varying highp vec2 vTexcoord;

void main() {
  sourceTexture;
  
  // 1. Prepare the coordinate system.
  highp vec2 center = abs(vTexcoord - 0.5) * 2.0; // [0, 1] to [-1, 1].
  // Aspect ratio correction: nullify the longer dimension near the center, so total non-zero length
  // of both dimensions is equal. Normalize it back to [-1, 1].
  center = clamp(center - distanceShift, 0.0, 1.0) / (1.0 - distanceShift);
  
  // 2. Create distance field.
  highp float dist;
  if (corner == 0.0) {
    // Max semi-norm.
    dist = max(center.x, center.y);
  } else {
    // p-norm.
    center = pow(center.xy, vec2(corner));
    dist = center.x + center.y;
  }
  // Create transition region and clamp everywhere else.
  dist = smoothstep(edge1, edge0, dist);
  dist = pow(dist, transitionExponent);
  
  // 3. Add noise in the transition area.
  // Read noise and make it zero mean.
  highp vec3 noiseTriplet = texture2D(noiseTexture, vTexcoord).rgb - 0.5;
  highp float noise = dot(noiseTriplet, noiseChannelMixer) * noiseAmplitude;
  
  highp float frame;
  highp float contrastScalingFactor = 1.0 - 2.0 * abs(dist - 0.5);
  // Instead of using if-statement to add noise only for dist values in 0<dist<1 range, optimize
  // using mix-and-step statement.
  frame = mix(dist + noise * contrastScalingFactor, dist, step(1.0, dist));
  frame = mix(frame, 0.0, step(dist, 0.0));

  gl_FragColor = vec4(color*frame, frame);
}
