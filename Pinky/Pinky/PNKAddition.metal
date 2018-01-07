// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#include <metal_stdlib>

#include "PNKTemplatedIO.metal"

using namespace metal;

template <typename U, typename V, typename W>
void addition(U inputImageA, V inputImageB, W outputImage, ushort2 gridIndex, ushort arrayIndex) {
  if (gridIndex.x >= inputImageA.get_width() || gridIndex.y >= inputImageA.get_height()) {
    return;
  }

  half4 pixel = lt::read(inputImageA, gridIndex, arrayIndex) +
      lt::read(inputImageB, gridIndex, arrayIndex);
  lt::write(outputImage, pixel, gridIndex, arrayIndex);
}

kernel void additionSingle(texture2d<half, access::read> inputImageA [[texture(0)]],
                           texture2d<half, access::read> inputImageB [[texture(1)]],
                           texture2d<half, access::write> outputImage [[texture(2)]],
                           ushort2 gridIndex [[thread_position_in_grid]]) {
  addition(inputImageA, inputImageB, outputImage, gridIndex, 0);
}

kernel void additionArray(texture2d_array<half, access::read> inputImageA [[texture(0)]],
                          texture2d_array<half, access::read> inputImageB [[texture(1)]],
                          texture2d_array<half, access::write> outputImage [[texture(2)]],
                          ushort3 gridIndex [[thread_position_in_grid]]) {
  if (gridIndex.z >= inputImageA.get_array_size()) {
    return;
  }
  
  addition(inputImageA, inputImageB, outputImage,  gridIndex.xy, gridIndex.z);
}
