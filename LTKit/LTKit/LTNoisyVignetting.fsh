// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

// This shader creates a vignetting pattern by manipulating the distance field and adding noise
// in the transition region. See lightricks-research/enlight/Vignetting/ for a playground with the
// concepts used by this shader.

uniform sampler2D sourceTexture;
uniform sampler2D noiseTexture;

// Vignetting parameters.
uniform highp float spread; // Value in [0, 1] range. 0 - no transition,  1 - full transition.
uniform highp float corner;
uniform highp float noiseAmplitude;
uniform highp vec3 noiseChannelMixer;
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
  center = pow(center.xy, vec2(corner));
  
  // 2. Create distance field using p-norm.
  highp float dist = pow(center.x + center.y, 1.0 / corner);
  // Create transition region and clamp everywhere else.
  // Find the value in the corner: (1^p + 1^p)^(1/p) = 2^(1/p).
  highp float edge = pow(2.0, 1.0/corner);
  dist = smoothstep(edge *  (1.0 - spread), edge, dist);
  
  // 3. Add noise in the transition area.
  // Read noise and make it zero mean.
  highp vec3 noiseTriplet = texture2D(noiseTexture, vTexcoord).rgb - 0.5;
  highp float noise = dot(noiseTriplet, noiseChannelMixer) * noiseAmplitude;
  
  highp float contrastScalingFactor = 1.0 - 2.0 * abs(dist - 0.5);
  // Instead of using if-statement to add noise only for dist values in 0<dist<1 range, optimize
  // using mix-and-step statement.
  highp float vignettingMask = mix(dist + noise * contrastScalingFactor, dist, step(1.0, dist));
  vignettingMask = mix(vignettingMask, 0.0, step(dist, 0.0));
  
  gl_FragColor = vec4(vec3(vignettingMask), 1.0);
}
