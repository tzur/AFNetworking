// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Alex Gershovich.

// Source texture for 3D LUT transform.
uniform sampler2D sourceTexture;

// 3D LUT, packed in a texture.
uniform sampler2D lutTexture;

// Texture coordinates of the input pixel.
varying highp vec2 vTexcoord;

// The RGB dimension sizes in the 3D LUT.
uniform highp vec3 rgbDimensionSizes;

void main() {
  highp vec2 pixelSize = vec2(1.0 / rgbDimensionSizes[0],
                              1.0 / (rgbDimensionSizes[1] * rgbDimensionSizes[2]));
  highp float sliceCount = rgbDimensionSizes[2];

  // Scaling factor and offset for coordinates of lutTexture so that sampling always falls inside
  // a single slice, and never triggers linear interpolation across adjacent slices.
  highp float sliceSize = 1.0 / sliceCount;
  highp vec2 scale = vec2(1, sliceSize) - pixelSize;
  highp vec2 offset = 0.5 * pixelSize;

  highp vec4 originalColor = texture2D(sourceTexture, vTexcoord);

  highp float slice = floor(originalColor.b * (sliceCount - 1.0)) / sliceCount;
  highp float t = fract(originalColor.b * (sliceCount - 1.0));

  highp vec2 lookupCoord = scale * originalColor.rg + offset + vec2(0, slice);

  lowp vec3 color0 = texture2D(lutTexture, lookupCoord).rgb;
  lowp vec3 color1 = texture2D(lutTexture, lookupCoord + vec2(0, sliceSize)).rgb;

  gl_FragColor = vec4(mix(color0, color1, t), originalColor.a);
}
