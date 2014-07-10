// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

const int SAMPLE_COUNT = 2;

const int kEdgesModeGrey = 0;
const int kEdgesModeColor = 1;

uniform sampler2D sourceTexture;
uniform int edgesMode;

varying highp vec2 vTexcoord;
varying mediump vec2 vSampleCoords[SAMPLE_COUNT];

void main() {
  mediump vec3 color = texture2D(sourceTexture, vTexcoord).rgb;
  mediump vec3 edge = abs(color - texture2D(sourceTexture, vSampleCoords[0]).rgb);
  edge += abs(color - texture2D(sourceTexture, vSampleCoords[1]).rgb);
  
  if (edgesMode == kEdgesModeColor) {
    color = edge;
  } else if (edgesMode == kEdgesModeGrey) {
    // Default NTSC weights for color->luminance conversion.
    color = vec3(dot(edge, vec3(0.299, 0.587, 0.114)));
  }
  gl_FragColor = vec4(color, 1.0);
}
