// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#include <metal_stdlib>

using namespace metal;

/// Gamma value to use for correction.
constant float gamma [[function_constant(0)]];

kernel void gammaCorrect(texture2d<half, access::read> inputImage [[texture(0)]],
                         texture2d<half, access::write> outputImage [[texture(1)]],
                         uint2 gridIndex [[thread_position_in_grid]]) {
  if (gridIndex.x >= inputImage.get_width() || gridIndex.y >= inputImage.get_height()) {
    return;
  }

  half4 color = inputImage.read(gridIndex);
  color.rgb = pow(color.rgb, gamma);
  outputImage.write(color, gridIndex);
}
