// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

uniform sampler2D sourceTexture;
uniform sampler2D noiseTexture;

// Wide frame settings.
uniform highp float edge0;
uniform highp float edge1;
uniform highp float maxVal;
uniform highp float minVal;
uniform highp float corner;
uniform highp float transitionBoost;
uniform highp vec3 noiseChannelMixer;
uniform highp float noiseAmplitude;
uniform highp float contrastScalingBoost;
uniform highp float aspectRatio; // Width / Height.

varying highp vec2 vTexcoord;

void main() {
  sourceTexture;
  
  transitionBoost;
  minVal;
  maxVal;
  noiseTexture;
  corner;
  noiseChannelMixer;
  noiseAmplitude;
  contrastScalingBoost;
  aspectRatio;
  
  highp vec2 center = (vTexcoord - 0.5); // [0:1] to [-0.5:0.5].
  highp float dist;
  if (corner == 0.0) {
    center = abs(center);
    dist = max(center.x, center.y);
  } else {
    center = pow(abs(center.xy), vec2(corner));
    dist = center.x + center.y;
  }
  // Create transition region and clamp everywhere else.
  dist = smoothstep(edge1, edge0, dist);
  dist = pow(dist, transitionBoost);
  dist = clamp((dist - minVal)/(maxVal - minVal), 0.0, 1.0);
  
  gl_FragColor = vec4(dist, 0.0, 0.0, 1.0);
}
