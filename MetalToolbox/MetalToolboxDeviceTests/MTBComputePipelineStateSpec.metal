// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#include <metal_stdlib>

using namespace metal;

constant float coefficient [[function_constant(0)]];
constant float coefficient2 [[function_constant(1)]];

kernel void functionWithoutConstants(texture2d<half, access::read> inputImage [[texture(0)]],
                                     texture2d<half, access::write> outputImage [[texture(1)]],
                                     uint2 gridIndex [[thread_position_in_grid]]) {
  half4 pixel = inputImage.read(gridIndex);
  outputImage.write(pixel, gridIndex);
}

kernel void functionWithConstants(texture2d<half, access::read> inputImage [[texture(0)]],
                                  texture2d<half, access::write> outputImage [[texture(1)]],
                                  uint2 gridIndex [[thread_position_in_grid]]) {
  half4 pixel = inputImage.read(gridIndex);
  pixel = clamp((half)coefficient * coefficient2 * pixel, 0.h, 1.h);
  outputImage.write(pixel, gridIndex);
}
