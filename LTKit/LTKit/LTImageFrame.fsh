// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

const int kFrameTypeStretch = 0;
const int kFrameTypeRepeat = 1;
const int kFrameTypeFit = 2;

uniform lowp sampler2D sourceTexture;
uniform lowp sampler2D frameTexture;

uniform mediump float aspectRatio; // Width / Height.
// In the repetition mode, this factor is the number of times to repeat the central part of the
// frame to fit the longer dimension of the image.
uniform mediump float repetitionFactor;
// Factor to apply on the frame's width - to resize it.
uniform mediump float frameWidthFactor;
uniform int frameType;

varying highp vec2 vTexcoord;

// Shader blends a rectangular image with a square, semi-transparent frame.
// The shader supports 3 following square-to-rectangle mapping modes:
// 1. Stretching the central part of the longer dimension.
// 2. Repeating the central part of the longer dimension integer number of times.
// 3. Fitting the square frame in the middle of the image rectangle.
// The support for integer (and not real) repetition factor is intentional. This makes it easier for
// the designers make matching boundary conditions.
//
// General observations:
// - While width or height can be the larger dimension, reduce it to one scenario by flipping the
// sourceTexture coordinate.
// - Shorter dimension always maps "as is".
// In order to understand how this shader remaps the sourceTexture coordinates, it is advised to use
// pen and paper and prepare a remapping diagram.
// Remapping diagram should include the square input range [0-1] and the re-mapped output range.
// For the first two cases, we use a "uniform nine-cut" strategy, where the frame's square is cut
// into 3 uniform veretical and then horizontal parts, creating 9-partition of the square.
// The mapping of the longer dimension can be visualized by drawing two lines partitioned into
// three parts. First line is the original square coordinates and the second line are rectangular
// coordinates. Now this boils down to the problem of re-mapping one range to another.
//
// Fitting case is even simpler, since we need to remap [0-1] to [a-b], where a/b are aspect ratio
// dependent points where the square starts and finishes. Before a and after b, boundary conditions
// are used.

void main() {
  lowp vec3 color = texture2D(sourceTexture, vTexcoord).rgb;
  
  highp vec2 texcoord = vTexcoord;
  highp float ratio;
  highp float invRatio;
  
  if (aspectRatio < 1.0) { // Height > Width.
    texcoord.xy = texcoord.yx;
    ratio = 1.0 / aspectRatio;
    invRatio = aspectRatio;
  } else {
    ratio = aspectRatio;
    invRatio = 1.0 / ratio;
  }
  
  // Resize frame's width - move to origin, zoom in and move back.
  texcoord -= vec2(0.5, 0.5);
  texcoord *= frameWidthFactor;
  texcoord += vec2(0.5, 0.5);
  
  highp float a;
  highp float b;
  
  if (frameType == kFrameTypeFit) {
    a = (ratio - 1.0) * (0.5 * invRatio);
    b = 1.0 - a;
    texcoord.x = (texcoord.x - a) / (b - a);
  } else { // Nine-cut.
    a = 0.3333 * invRatio;
    b = 1.0 - (0.3333 * invRatio);
    
    // Stretch (1.0) the central part - for kFrameTypeStretch.
    highp float factor = 1.0;
    if (frameType == kFrameTypeRepeat) {
      // Repeat central part.
      factor = repetitionFactor;
    }
    
    if (texcoord.x < a) {
      texcoord.x = texcoord.x * ratio;
    } else if (texcoord.x > b) {
      texcoord.x = 1.0 - 0.3333 * ratio + (texcoord.x - 0.6667) * ratio;
    } else {
      texcoord.x = mod((texcoord.x - a) / (b - a) * factor, 1.0) * 0.3333 + 0.3333;
    }
  }
  
  if (aspectRatio < 1.0) { // Height > Width.
    texcoord.xy = texcoord.yx;
  }
  
  highp vec4 frame = texture2D(frameTexture, texcoord).rgba;
  // Pre-multiplied alpha blending.
  gl_FragColor = vec4((1.0-frame.a) * color + frame.rgb, 1.0);
}

