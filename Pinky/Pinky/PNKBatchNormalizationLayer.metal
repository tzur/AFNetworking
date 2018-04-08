// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#include <metal_stdlib>

#include "PNKActivation.metal.h"
#include "PNKTemplatedIO.metal"

using namespace metal;

constant const ushort activationType [[function_constant(0)]];
constant const bool hasAlphaBuffer [[function_constant(1)]];
constant const bool hasBetaBuffer [[function_constant(2)]];

template <typename U, typename V>
void batchNorm(constant half4 *scale, constant half4 *shift, constant half4 *alpha,
               constant half4 *beta, U inputImage, V outputImage, uint2 gridIndex,
               uint arrayIndex) {
  const half4 textureScale = scale[arrayIndex];
  const half4 textureShift = shift[arrayIndex];

  half4 inputValue = lt::read(inputImage, gridIndex, arrayIndex);
  half4 outputValue = inputValue * textureScale + textureShift;
  half4 valueAfterActivation = pnk::ActivatedValue(outputValue, activationType, alpha, beta,
                                                   arrayIndex);

  lt::write(outputImage, valueAfterActivation, gridIndex, arrayIndex);
}

kernel void batchNormArray(constant half4 *scale [[buffer(0)]],
                           constant half4 *shift [[buffer(1)]],
                           constant half4 *alpha [[buffer(2), function_constant(hasAlphaBuffer)]],
                           constant half4 *beta [[buffer(3), function_constant(hasBetaBuffer)]],
                           texture2d_array<half, access::read> inputImage [[texture(0)]],
                           texture2d_array<half, access::write> outputImage [[texture(1)]],
                           uint3 gridIndex [[thread_position_in_grid]]) {
  const uint2 outputSize = uint2(outputImage.get_width(), outputImage.get_height());
  if (gridIndex.x >= outputSize.x || gridIndex.y >= outputSize.y ||
      gridIndex.z >= outputImage.get_array_size()) {
    return;
  }

  batchNorm(scale, shift, alpha, beta, inputImage, outputImage, gridIndex.xy, gridIndex.z);
}

kernel void batchNormSingle(constant half4 *scale [[buffer(0)]],
                            constant half4 *shift [[buffer(1)]],
                            constant half4 *alpha [[buffer(2), function_constant(hasAlphaBuffer)]],
                            constant half4 *beta [[buffer(3), function_constant(hasBetaBuffer)]],
                            texture2d<half, access::read> inputImage [[texture(0)]],
                            texture2d<half, access::write> outputImage [[texture(1)]],
                            uint3 gridIndex [[thread_position_in_grid]]) {
  const uint2 outputSize = uint2(outputImage.get_width(), outputImage.get_height());
  if (gridIndex.x >= outputSize.x || gridIndex.y >= outputSize.y) {
    return;
  }
  batchNorm(scale, shift, alpha, beta, inputImage, outputImage, gridIndex.xy, 0);
}
