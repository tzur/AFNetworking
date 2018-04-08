// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#include <metal_stdlib>

#include "PNKActivation.metal.h"
#include "PNKTemplatedIO.metal"

using namespace metal;

constant const ushort activationType [[function_constant(0)]];
constant const bool hasAlphaBuffer [[function_constant(1)]];
constant const bool hasBetaBuffer [[function_constant(2)]];

template <typename U, typename V>
void activation(constant half4 *alpha, constant half4 *beta, U inputImage, V outputImage,
                uint2 gridIndex, uint arrayIndex) {
  const uint2 outputSize = uint2(outputImage.get_width(), outputImage.get_height());
  if (gridIndex.x >= outputSize.x || gridIndex.y >= outputSize.y) {
    return;
  }
  half4 inputValue = lt::read(inputImage, gridIndex, arrayIndex);
  half4 outputValue = pnk::ActivatedValue(inputValue, activationType, alpha, beta, arrayIndex);
  lt::write(outputImage, outputValue, gridIndex, arrayIndex);
}

kernel void activationArray(constant half4 *alpha [[buffer(0), function_constant(hasAlphaBuffer)]],
                            constant half4 *beta [[buffer(1), function_constant(hasBetaBuffer)]],
                            texture2d_array<half, access::read> inputImage [[texture(0)]],
                            texture2d_array<half, access::write> outputImage [[texture(1)]],
                            uint3 gridIndex [[thread_position_in_grid]]) {
  if (gridIndex.z >= outputImage.get_array_size()) {
    return;
  }

  activation(alpha, beta, inputImage, outputImage, gridIndex.xy, gridIndex.z);
}

kernel void activationSingle(constant half4 *alpha [[buffer(0), function_constant(hasAlphaBuffer)]],
                             constant half4 *beta [[buffer(1), function_constant(hasBetaBuffer)]],
                             texture2d<half, access::read> inputImage [[texture(0)]],
                             texture2d<half, access::write> outputImage [[texture(1)]],
                             uint3 gridIndex [[thread_position_in_grid]]) {
  activation(alpha, beta, inputImage, outputImage, gridIndex.xy, 0);
}
