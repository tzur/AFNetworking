// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#include <metal_stdlib>

#include "PNKNeuralNetworkTypeDefinitions.h"
#include "PNKTemplatedIO.metal"

using namespace metal;

constant const ushort unaryType [[function_constant(0)]];
constant const half alpha [[function_constant(1)]];
constant const half scale [[function_constant(2)]];
constant const half shift [[function_constant(3)]];
constant const half epsilon [[function_constant(4)]];

half4 unaryFunctionValue(half4 value) {
  switch ((pnk::UnaryType)unaryType) {
    case pnk::UnaryTypeSqrt:
      return sqrt(value);
    case pnk::UnaryTypeRsqrt:
      return 1.h / sqrt(value + epsilon);
    case pnk::UnaryTypeInverse:
      return 1.h / (value + epsilon);
    case pnk::UnaryTypePower:
      return pow(value, alpha);
    case pnk::UnaryTypeExp:
      return exp(value);
    case pnk::UnaryTypeLog:
      return log(value);
    case pnk::UnaryTypeAbs:
      return abs(value);
    case pnk::UnaryTypeThreshold:
      return max(alpha, value);
    default:
      return value;
  }
}

template <typename U, typename V>
void unary(U inputImage, V outputImage, uint2 gridIndex, uint arrayIndex) {
  const uint2 outputSize = uint2(outputImage.get_width(), outputImage.get_height());
  if (gridIndex.x >= outputSize.x || gridIndex.y >= outputSize.y) {
    return;
  }
  half4 inputValue = lt::read(inputImage, gridIndex, arrayIndex);
  inputValue = shift + scale * inputValue;
  half4 outputValue = unaryFunctionValue(inputValue);
  lt::write(outputImage, outputValue, gridIndex, arrayIndex);
}

kernel void unaryArray(texture2d_array<half, access::read> inputImage [[texture(0)]],
                       texture2d_array<half, access::write> outputImage [[texture(1)]],
                       uint3 gridIndex [[thread_position_in_grid]]) {
  if (gridIndex.z >= outputImage.get_array_size()) {
    return;
  }

  unary(inputImage, outputImage, gridIndex.xy, gridIndex.z);
}

kernel void unarySingle(texture2d<half, access::read> inputImage [[texture(0)]],
                        texture2d<half, access::write> outputImage [[texture(1)]],
                        uint3 gridIndex [[thread_position_in_grid]]) {
  unary(inputImage, outputImage, gridIndex.xy, 0);
}
