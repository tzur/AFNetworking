// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#include <metal_stdlib>

using namespace metal;

kernel void addition(texture2d<half, access::read> inputImageA [[texture(0)]],
                     texture2d<half, access::read> inputImageB [[texture(1)]],
                     texture2d<half, access::write> outputImage [[texture(2)]],
                     ushort2 gridIndex [[thread_position_in_grid]]) {
  if (gridIndex.x >= inputImageA.get_width() || gridIndex.y >= inputImageA.get_height()) {
    return;
  }
  
  half4 color = inputImageA.read(gridIndex) + inputImageB.read(gridIndex);
  outputImage.write(color, gridIndex);
}

kernel void additionArray(texture2d_array<half, access::read> inputImageA [[texture(0)]],
                          texture2d_array<half, access::read> inputImageB [[texture(1)]],
                          texture2d_array<half, access::write> outputImage [[texture(2)]],
                          ushort3 gridIndex [[thread_position_in_grid]]) {
  if (gridIndex.x >= inputImageA.get_width() || gridIndex.y >= inputImageA.get_height() ||
      gridIndex.z >= inputImageA.get_array_size()) {
    return;
  }
  
  half4 color = inputImageA.read(gridIndex.xy, gridIndex.z) + inputImageB.read(gridIndex.xy,
                                                                               gridIndex.z);
  outputImage.write(color, gridIndex.xy, gridIndex.z);
}
