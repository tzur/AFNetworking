// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#include <metal_stdlib>
#include <metal_types.h>

#include "PNKTemplatedIO.metal"

using namespace metal;

constant half scale [[function_constant(0)]];

template <typename T>
void argmax(T inputImage, texture2d<half, access::write> outputImage, ushort2 gridIndex,
            ushort featureChannels) {
  const ushort2 outputSize = ushort2(outputImage.get_width(), outputImage.get_height());
  if (any(gridIndex >= outputSize)) {
    return;
  }

  half maxValue = -MAXHALF;
  ushort indexOfMaxValue = 0;
  ushort textureCount = (featureChannels + 3) / 4;
  for (ushort arrayIndex = 0; arrayIndex < textureCount; ++arrayIndex) {
    half4 pixel = lt::read(inputImage, gridIndex, arrayIndex);
    for (ushort channel = 0; channel < min(4, featureChannels - 4 * arrayIndex); ++channel) {
      indexOfMaxValue = (pixel[channel] > maxValue) ? (4 * arrayIndex + channel) : indexOfMaxValue;
      maxValue = (pixel[channel] > maxValue) ? pixel[channel] : maxValue;
    }
  }

  outputImage.write(half4(half(indexOfMaxValue) * scale), gridIndex);
}

kernel void argmaxSingle(constant ushort *featureChannels [[buffer(0)]],
                         texture2d<half, access::read> inputImage [[texture(0)]],
                         texture2d<half, access::write> outputImage [[texture(1)]],
                         ushort2 gridIndex [[thread_position_in_grid]]) {
  argmax(inputImage, outputImage, gridIndex, featureChannels[0]);
}

kernel void argmaxArray(constant ushort *featureChannels [[buffer(0)]],
                        texture2d_array<half, access::read> inputImage [[texture(0)]],
                        texture2d<half, access::write> outputImage [[texture(1)]],
                        ushort2 gridIndex [[thread_position_in_grid]]) {
  argmax(inputImage, outputImage, gridIndex, featureChannels[0]);
}
