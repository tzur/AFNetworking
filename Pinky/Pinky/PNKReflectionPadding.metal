// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#include <metal_stdlib>

using namespace metal;

/// Left and top padding.
constant short2 paddingLeftTop [[function_constant(0)]];
/// Right and bottom padding.
constant short2 paddingRightBottom [[function_constant(1)]];

ushort2 calculateReadCoordinates(uint2 gridIndex, const uint2 outputSize) {
  short2 inputSize = (short2)outputSize - paddingLeftTop - paddingRightBottom;

  short2 readCoordinates = abs((short2)gridIndex - paddingLeftTop);
  readCoordinates = min(readCoordinates, 2 * inputSize - readCoordinates - 2);

  return ushort2((ushort)readCoordinates.x, (ushort)readCoordinates.y);
}

kernel void reflectionPaddingSingle(texture2d<half, access::read> inputImage [[texture(0)]],
                              texture2d<half, access::write> outputImage [[texture(1)]],
                              uint2 gridIndex [[thread_position_in_grid]]) {
  const uint2 outputSize = uint2(outputImage.get_width(), outputImage.get_height());
  if (gridIndex.x >= outputSize.x || gridIndex.y >= outputSize.y) {
    return;
  }

  ushort2 readCoordinates = calculateReadCoordinates(gridIndex, outputSize);
  outputImage.write(inputImage.read(readCoordinates), gridIndex);
}

kernel void reflectionPaddingArray(texture2d_array<half, access::read> inputImage [[texture(0)]],
                                   texture2d_array<half, access::write> outputImage [[texture(1)]],
                                   uint3 gridIndex [[thread_position_in_grid]]) {
  const uint2 outputSize = uint2(outputImage.get_width(), outputImage.get_height());
  if (gridIndex.x >= outputSize.x || gridIndex.y >= outputSize.y ||
      gridIndex.z >= outputImage.get_array_size()) {
    return;
  }

  ushort2 readCoordinates = calculateReadCoordinates(gridIndex.xy, outputSize);
  outputImage.write(inputImage.read(readCoordinates, gridIndex.z), gridIndex.xy, gridIndex.z);
}
