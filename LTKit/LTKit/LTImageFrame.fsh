// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#extension GL_EXT_shader_framebuffer_fetch : require

const int kFrameTypeStretch = 0;
const int kFrameTypeRepeat = 1;
const int kFrameTypeFit = 2;
const int kFrameTypeIdentity = 3;

uniform bool readColorFromOutput;

uniform lowp sampler2D sourceTexture;
uniform lowp sampler2D baseTexture;
uniform lowp sampler2D baseMaskTexture;
uniform lowp sampler2D frameMaskTexture;

// Global alphas.
uniform mediump float globalBaseMaskAlpha;
uniform mediump float globalFrameMaskAlpha;

// Width / Height.
uniform mediump float aspectRatio;
// In the repetition mode, this factor is the number of times to repeat the central part of the
// frame to fit the longer dimension of the image.
uniform mediump float repetitionFactor;
// Factor to apply on the frame's width - to resize it.
uniform mediump float frameWidthFactor;
uniform int frameType;
// Changes the color of the frame.
uniform mediump vec3 frameColor;

// Tile related parameters.
uniform bool isTileable;
uniform mediump vec2 translation;
uniform mediump mat2 rotation;
uniform mediump vec2 scaling;

// Maps baseTexture and baseMask to full image size.
uniform bool mapBaseToFullImageSize;

varying highp vec2 vTexcoord;

// Shader blends a rectangular image with a square, semi-transparent frame.
// It supports tileable and non tileable textures.
// The shader also supports 3 following square-to-rectangle mapping modes:
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

// Returns tiled texture coordinate given a regular texture coordinate.
mediump vec2 toTiledTexcoord(in mediump vec2 texcoord) {
  texcoord.x = texcoord.x * aspectRatio;
  // 1. Center texture coordinate around (0, 0).
  mediump vec2 centered = texcoord - 0.5;
  // 2. Rotate point around center.
  mediump vec2 rotated = rotation * centered;
  // 3. Return texture coordinate to its previos location.
  rotated = rotated + 0.5;
  // 4. Do the tiling and translation.
  // TODO:(amits) check if removing the LTTextureWrapRepeat and putting here mod will work just as
  // fast. This will remove the requirement of power of two dimensions.
  mediump vec2 tiled = rotated * scaling + translation;
  tiled.x = tiled.x / aspectRatio;
  return tiled;
}

mediump vec2 repositionTexcoordAccoringToType(in mediump vec2 texcoord) {
  mediump float ratio;
  mediump float invRatio;
  
  if (aspectRatio < 1.0) { // Height > Width.
    texcoord.xy = texcoord.yx;
    ratio = 1.0 / aspectRatio;
    invRatio = aspectRatio;
  } else {
    ratio = aspectRatio;
    invRatio = 1.0 / ratio;
  }
  
  mediump float a;
  mediump float b;
  
  if (frameType == kFrameTypeFit) {
    a = (ratio - 1.0) * (0.5 * invRatio);
    b = 1.0 - a;
    texcoord.x = (texcoord.x - a) / (b - a);
  } else { // Nine-cut.
    a = 0.3333 * invRatio;
    b = 1.0 - (0.3333 * invRatio);
    
    // Stretch (1.0) the central part - for kFrameTypeStretch.
    mediump float factor = 1.0;
    if (frameType == kFrameTypeRepeat) {
      // Repeat central part.
      factor = repetitionFactor;
      
      // Resize frame's width in the case of repeat - move to origin, zoom in and move back. Does
      // not preserve frame width in image width and height dimensions.
      texcoord -= vec2(0.5, 0.5);
      texcoord *= frameWidthFactor;
      texcoord += vec2(0.5, 0.5);
    }
    
    texcoord.x = mix(texcoord.x * ratio,
                     mix(1.0 - 0.3333 * ratio + (texcoord.x - 0.6667) * ratio,
                         mod((texcoord.x - a) / (b - a) * factor, 1.0) * 0.3333 + 0.3333,
                         step(texcoord.x, b)), step(a, texcoord.x));
  }
  
  // Height > Width.
  if (aspectRatio < 1.0) {
    texcoord.xy = texcoord.yx;
  }
  
  // Resize frame's width in the case frame type is not repeat - move to origin, zoom in and move
  // back.
  if (frameType != kFrameTypeRepeat) {
    texcoord -= vec2(0.5, 0.5);
    texcoord *= frameWidthFactor;
    texcoord += vec2(0.5, 0.5);
  }
  
  return texcoord;
}

lowp vec4 normalBlend(in mediump vec3 Sca, in mediump vec3 Dca, in mediump float Sa,
                      in mediump float Da) {
  lowp vec4 normalBlend;
  normalBlend.rgb = Sa * Sca + (1.0 - Sa) * Dca;
  normalBlend.a = Sa + Da - Sa * Da;
  return normalBlend;
}

void main() {
  lowp vec3 imageColor;

  // To avoid undefined OpenGL behaviors, read from the input texture using gl_LastFragData instead
  // of using the sampler, which is forbidden.
  if (readColorFromOutput) {
    imageColor = gl_LastFragData[0].rgb;
  } else {
    imageColor = texture2D(sourceTexture , vTexcoord).rgb;
  }
  highp vec2 texcoord = vTexcoord;
  if (frameType != kFrameTypeIdentity) {
    texcoord = repositionTexcoordAccoringToType(vTexcoord);
  }
  lowp float frameMask = texture2D(frameMaskTexture, texcoord).r;
  lowp vec4 baseTextureColor;
  lowp float baseMask;
  
  if (isTileable) {
    mediump vec2 tiledcoord = toTiledTexcoord(vTexcoord);
    baseTextureColor = texture2D(baseTexture, tiledcoord);
    baseMask = texture2D(baseMaskTexture, tiledcoord).r;
  } else {
    if (mapBaseToFullImageSize) {
      baseTextureColor = texture2D(baseTexture, vTexcoord);
      baseMask = texture2D(baseMaskTexture, vTexcoord).r;
    } else {
      baseTextureColor = texture2D(baseTexture, texcoord);
      baseMask = texture2D(baseMaskTexture, texcoord).r;
    }
  }
  baseMask = baseMask * globalBaseMaskAlpha;
  
  // Blend baseMask with baseTexture.
  lowp vec4 coloredBaseMask = vec4(frameColor, baseMask);
  lowp vec4 coloredBaseTextureWithMask = normalBlend(coloredBaseMask.rgb, baseTextureColor.rgb,
                                                     coloredBaseMask.a, baseTextureColor.a);
  
  // Blend baseTexture+Mask with frameMask.
  frameMask = frameMask * coloredBaseTextureWithMask.a * globalFrameMaskAlpha;
  gl_FragColor = vec4((1.0 - frameMask) * imageColor, (1.0 - frameMask)) +
      vec4(frameMask * coloredBaseTextureWithMask.rgb, frameMask);
}
