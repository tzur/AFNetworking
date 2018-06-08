// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#include <metal_stdlib>

#include "PNKTemplatedIO.metal"

using namespace metal;

kernel void translatePixelValue(texture2d<half, access::read> inputImage [[texture(0)]],
                                texture2d<half, access::write> outputImage [[texture(1)]],
                                constant half *translationTable [[buffer(0)]],
                                uint2 gridIndex [[thread_position_in_grid]]) {
  const uint2 outputSize = uint2(outputImage.get_width(), outputImage.get_height());
  if (any(gridIndex >= outputSize)) {
    return;
  }

  half4 value = inputImage.read(gridIndex);
  half clampedValue = clamp(value.r, 0.h, 1.h);
  ushort indexInTable = (ushort)round(clampedValue * 255.h);
  half newValue = translationTable[indexInTable];
  outputImage.write(half4(newValue), gridIndex);
}
