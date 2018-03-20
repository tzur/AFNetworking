// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#include <metal_stdlib>

#include "PNKTemplatedIO.metal"
#include "PNKTypeDefinitions.h"

using namespace metal;

constant ushort operation [[function_constant(0)]];

template <typename U, typename V>
void arithmetic(U inputImageA, U inputImageB, V outputImage, ushort2 gridIndex, ushort arrayIndex) {
  if (gridIndex.x >= inputImageA.get_width() || gridIndex.y >= inputImageA.get_height()) {
    return;
  }

  half4 inputA = lt::read(inputImageA, gridIndex, arrayIndex);
  half4 inputB = lt::read(inputImageB, gridIndex, arrayIndex);
  half4 output;
  switch ((pnk::ArithmeticOperation)operation) {
    case pnk::ArithmeticOperationAddition:
      output = inputA + inputB;
      break;
    case pnk::ArithmeticOperationSubstraction:
      output = inputA - inputB;
      break;
    case pnk::ArithmeticOperationMultiplication:
      output = inputA * inputB;
      break;
    case pnk::ArithmeticOperationDivision:
      output = inputA / inputB;
      break;
  }
  lt::write(outputImage, output, gridIndex, arrayIndex);
}

kernel void arithmeticSingle(texture2d<half, access::read> inputImageA [[texture(0)]],
                             texture2d<half, access::read> inputImageB [[texture(1)]],
                             texture2d<half, access::write> outputImage [[texture(2)]],
                             ushort2 gridIndex [[thread_position_in_grid]]) {
  arithmetic(inputImageA, inputImageB, outputImage, gridIndex, 0);
}

kernel void arithmeticArray(texture2d_array<half, access::read> inputImageA [[texture(0)]],
                            texture2d_array<half, access::read> inputImageB [[texture(1)]],
                            texture2d_array<half, access::write> outputImage [[texture(2)]],
                            ushort3 gridIndex [[thread_position_in_grid]]) {
  if (gridIndex.z >= inputImageA.get_array_size()) {
    return;
  }

  arithmetic(inputImageA, inputImageB, outputImage,  gridIndex.xy, gridIndex.z);
}
