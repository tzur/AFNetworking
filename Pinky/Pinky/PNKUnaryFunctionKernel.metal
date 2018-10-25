// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#include <metal_stdlib>

#include "PNKActivation.metal.h"
#include "PNKTemplatedIO.metal"

using namespace metal;

constant const ushort unaryType [[function_constant(0)]];

half4 UnaryFunctionValue(half4 value, half alpha) {
  switch ((pnk::UnaryType)unaryType) {
    case pnk::UnaryTypeThreshold:
      return max(alpha, value);
  }

  return value;
}

template <typename U, typename V>
void unary(half alpha, half shift, half scale, U inputImage,
           V outputImage, uint2 gridIndex, uint arrayIndex) {
  const uint2 outputSize = uint2(outputImage.get_width(), outputImage.get_height());
  if (gridIndex.x >= outputSize.x || gridIndex.y >= outputSize.y) {
    return;
  }
  half4 inputValue = lt::read(inputImage, gridIndex, arrayIndex);
  inputValue = shift + scale * inputValue;
  half4 outputValue = UnaryFunctionValue(inputValue, alpha);
  lt::write(outputImage, outputValue, gridIndex, arrayIndex);
}

kernel void unaryArray(constant half *alpha [[buffer(0)]],
                       constant half *shift [[buffer(1)]],
                       constant half *scale [[buffer(2)]],
                       texture2d_array<half, access::read> inputImage [[texture(0)]],
                       texture2d_array<half, access::write> outputImage [[texture(1)]],
                       uint3 gridIndex [[thread_position_in_grid]]) {
  if (gridIndex.z >= outputImage.get_array_size()) {
    return;
  }

  unary(alpha[0], shift[0], scale[0], inputImage, outputImage, gridIndex.xy, gridIndex.z);
}

kernel void unarySingle(constant half *alpha [[buffer(0)]],
                        constant half *shift [[buffer(1)]],
                        constant half *scale [[buffer(2)]],
                        texture2d<half, access::read> inputImage [[texture(0)]],
                        texture2d<half, access::write> outputImage [[texture(1)]],
                        uint3 gridIndex [[thread_position_in_grid]]) {
  unary(alpha[0], shift[0], scale[0], inputImage, outputImage, gridIndex.xy, 0);
}
