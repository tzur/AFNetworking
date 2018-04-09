// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#include <metal_stdlib>

using namespace metal;

kernel void fillWithZeroesSingle(texture2d<half, access::write> outputImage [[texture(0)]],
                                 uint2 gridIndex [[thread_position_in_grid]]) {
  const uint2 outputSize(outputImage.get_width(), outputImage.get_height());
  if (any(gridIndex >= outputSize)) {
    return;
  }

  half4 zero(0.h);
  outputImage.write(zero, gridIndex);
}

kernel void fillWithZeroesArray(texture2d_array<half, access::write> outputImage [[texture(0)]],
                                uint3 gridIndex [[thread_position_in_grid]]) {
  const uint3 outputSize(outputImage.get_width(), outputImage.get_height(),
                         outputImage.get_array_size());
  if (any(gridIndex >= outputSize)) {
    return;
  }

  half4 zero(0.h);
  outputImage.write(zero, gridIndex.xy, gridIndex.z);
}
