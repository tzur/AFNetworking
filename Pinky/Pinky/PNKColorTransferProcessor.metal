// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#include <metal_stdlib>

using namespace metal;

kernel void convertByteToFloat(texture2d<float, access::read> texture [[texture(0)]],
                               device float4 *output [[buffer(0)]],
                               uint2 index [[thread_position_in_grid]]) {
  const uint width = texture.get_width();
  if (index.x >= width || index.y >= texture.get_height()) {
    return;
  }

  const float4 color = texture.read(index);
  output[index.y * width + index.x] = color;
}

kernel void cloneLattice(constant float3 *input [[buffer(0)]],
                         device float3 *output [[buffer(1)]],
                         uint index [[thread_position_in_grid]]) {
  output[index] = input[index];
}
