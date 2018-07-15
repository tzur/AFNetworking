// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#include <metal_stdlib>

using namespace metal;

kernel void fillWithZeros(texture2d<half, access::write> output [[texture(2)]],
                           uint2 gridIndex [[thread_position_in_grid]]) {
  output.write(half4(0), gridIndex);
}
