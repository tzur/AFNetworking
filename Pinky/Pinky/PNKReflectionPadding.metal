// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#include <metal_stdlib>

using namespace metal;

/// Padding in both dimensions.
constant ushort2 paddingSize [[function_constant(0)]];

inline ushort2 calculateReadCoordinates(ushort2 gridIndex, const ushort2 outputSize) {
  short2 readCoordinates = short2(gridIndex) - short2(paddingSize);
  const short2 inputSize = short2(outputSize) - short2(paddingSize) * 2;

  readCoordinates = abs(readCoordinates);
  readCoordinates = min(readCoordinates, 2 * inputSize - readCoordinates - 2);
  return ushort2(readCoordinates);
}

kernel void reflectionPadding(texture2d<half, access::read> inputImage [[texture(0)]],
                              texture2d<half, access::write> outputImage [[texture(1)]],
                              ushort2 gridIndex [[thread_position_in_grid]]) {
  const ushort2 outputSize = ushort2(outputImage.get_width(), outputImage.get_height());
  if (gridIndex.x >= outputSize.x || gridIndex.y >= outputSize.y) {
    return;
  }

  ushort2 readCoordinates = calculateReadCoordinates(gridIndex, outputSize);
  outputImage.write(inputImage.read(readCoordinates), gridIndex);
}

kernel void reflectionPaddingArray(texture2d_array<half, access::read> inputImage [[texture(0)]],
                                   texture2d_array<half, access::write> outputImage [[texture(1)]],
                                   ushort3 gridIndex [[thread_position_in_grid]]) {
  const ushort2 outputSize = ushort2(outputImage.get_width(), outputImage.get_height());
  if (gridIndex.x >= outputSize.x || gridIndex.y >= outputSize.y ||
      gridIndex.z >= outputImage.get_array_size()) {
    return;
  }

  ushort2 readCoordinates = calculateReadCoordinates(gridIndex.xy, outputSize);
  outputImage.write(inputImage.read(readCoordinates, gridIndex.z), gridIndex.xy, gridIndex.z);
}
