// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#include <metal_stdlib>

#include "PNKTemplatedIO.metal"

using namespace metal;

constant uint2 marginsLeftTop [[function_constant(0)]];

template <typename U, typename V>
void crop(U inputImage, V outputImage, uint2 gridIndex, uint arrayIndex) {
  const uint2 outputSize = uint2(outputImage.get_width(), outputImage.get_height());
  if (any(gridIndex >= outputSize)) {
    return;
  }

  half4 pixel = lt::read(inputImage, gridIndex + marginsLeftTop, arrayIndex);
  lt::write(outputImage, pixel, gridIndex, arrayIndex);
}

kernel void cropSingle(texture2d<half, access::read> inputImage [[texture(0)]],
                       texture2d<half, access::write> outputImage [[texture(1)]],
                       uint2 gridIndex [[thread_position_in_grid]]) {
  crop(inputImage, outputImage, gridIndex, 0);
}

kernel void cropArray(texture2d_array<half, access::read> inputImage [[texture(0)]],
                      texture2d_array<half, access::write> outputImage [[texture(1)]],
                      uint3 gridIndex [[thread_position_in_grid]]) {
  if (gridIndex.z >= outputImage.get_array_size()) {
    return;
  }
  crop(inputImage, outputImage, gridIndex.xy, gridIndex.z);
}
