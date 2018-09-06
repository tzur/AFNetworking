// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#include <metal_stdlib>

#include "PNKTemplatedIO.metal"
#include "PNKTypeDefinitions.h"

using namespace metal;

constant ushort operation [[function_constant(0)]];

half4 operationResult(half4 inputA, half4 inputB, pnk::ArithmeticOperation operation) {
  switch (operation) {
    case pnk::ArithmeticOperationAddition:
      return inputA + inputB;
    case pnk::ArithmeticOperationSubstraction:
      return inputA - inputB;
    case pnk::ArithmeticOperationMultiplication:
      return inputA * inputB;
    case pnk::ArithmeticOperationDivision:
      return inputA / inputB;
    default:
      return half4(0.h);
  }
}

template <typename U, typename V>
void arithmetic(U inputImageA, U inputImageB, V outputImage, uint2 gridIndex, ushort arrayIndex) {
  if (gridIndex.x >= outputImage.get_width() || gridIndex.y >= outputImage.get_height()) {
    return;
  }

  half4 inputA = lt::read(inputImageA, gridIndex, arrayIndex);
  half4 inputB = lt::read(inputImageB, gridIndex, arrayIndex);
  half4 output = operationResult(inputA, inputB, (pnk::ArithmeticOperation)operation);
  lt::write(outputImage, output, gridIndex, arrayIndex);
}

kernel void arithmeticSingle(texture2d<half, access::read> inputImageA [[texture(0)]],
                             texture2d<half, access::read> inputImageB [[texture(1)]],
                             texture2d<half, access::write> outputImage [[texture(2)]],
                             uint2 gridIndex [[thread_position_in_grid]]) {
  arithmetic(inputImageA, inputImageB, outputImage, gridIndex, 0);
}

kernel void arithmeticArray(texture2d_array<half, access::read> inputImageA [[texture(0)]],
                            texture2d_array<half, access::read> inputImageB [[texture(1)]],
                            texture2d_array<half, access::write> outputImage [[texture(2)]],
                            uint3 gridIndex [[thread_position_in_grid]]) {
  if (gridIndex.z >= outputImage.get_array_size()) {
    return;
  }

  arithmetic(inputImageA, inputImageB, outputImage, gridIndex.xy, gridIndex.z);
}

template <typename U, typename V, typename W>
void arithmeticBroadcastPrimary(U inputImageA, V inputImageB, W outputImage, uint2 gridIndex,
                                ushort arrayIndex) {
  if (gridIndex.x >= outputImage.get_width() || gridIndex.y >= outputImage.get_height()) {
    return;
  }

  half4 inputA = half4(lt::read(inputImageA, gridIndex, 0).x);
  half4 inputB = lt::read(inputImageB, gridIndex, arrayIndex);
  half4 output = operationResult(inputA, inputB, (pnk::ArithmeticOperation)operation);
  lt::write(outputImage, output, gridIndex, arrayIndex);
}

kernel void arithmeticSingleBroadcastPrimary(
    texture2d<half, access::read> inputImageA [[texture(0)]],
    texture2d<half, access::read> inputImageB [[texture(1)]],
    texture2d<half, access::write> outputImage [[texture(2)]],
    uint2 gridIndex [[thread_position_in_grid]]) {
  arithmeticBroadcastPrimary(inputImageA, inputImageB, outputImage, gridIndex, 0);
}

kernel void arithmeticArrayBroadcastPrimary(
    texture2d<half, access::read> inputImageA [[texture(0)]],
    texture2d_array<half, access::read> inputImageB [[texture(1)]],
    texture2d_array<half, access::write> outputImage [[texture(2)]],
    uint3 gridIndex [[thread_position_in_grid]]) {
  if (gridIndex.z >= outputImage.get_array_size()) {
    return;
  }

  arithmeticBroadcastPrimary(inputImageA, inputImageB, outputImage, gridIndex.xy, gridIndex.z);
}

template <typename U, typename V, typename W>
void arithmeticBroadcastSecondary(U inputImageA, V inputImageB, W outputImage, uint2 gridIndex,
                                  ushort arrayIndex) {
  if (gridIndex.x >= outputImage.get_width() || gridIndex.y >= outputImage.get_height()) {
    return;
  }

  half4 inputA = lt::read(inputImageA, gridIndex, arrayIndex);
  half4 inputB = half4(lt::read(inputImageB, gridIndex, 0).x);
  half4 output = operationResult(inputA, inputB, (pnk::ArithmeticOperation)operation);
  lt::write(outputImage, output, gridIndex, arrayIndex);
}

kernel void arithmeticSingleBroadcastSecondary(
    texture2d<half, access::read> inputImageA [[texture(0)]],
    texture2d<half, access::read> inputImageB [[texture(1)]],
    texture2d<half, access::write> outputImage [[texture(2)]],
    uint2 gridIndex [[thread_position_in_grid]]) {
  arithmeticBroadcastSecondary(inputImageA, inputImageB, outputImage, gridIndex, 0);
}

kernel void arithmeticArrayBroadcastSecondary(
    texture2d_array<half, access::read> inputImageA [[texture(0)]],
    texture2d<half, access::read> inputImageB [[texture(1)]],
    texture2d_array<half, access::write> outputImage [[texture(2)]],
    uint3 gridIndex [[thread_position_in_grid]]) {
  if (gridIndex.z >= outputImage.get_array_size()) {
    return;
  }

  arithmeticBroadcastSecondary(inputImageA, inputImageB, outputImage, gridIndex.xy, gridIndex.z);
}
