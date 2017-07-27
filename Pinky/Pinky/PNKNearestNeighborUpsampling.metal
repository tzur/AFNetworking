// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#include <metal_stdlib>

using namespace metal;

/// Factor of input magnification.
constant ushort magnificationFactor [[function_constant(0)]];

kernel void nearestNeighbor(texture2d<half, access::read> inputImage [[texture(0)]],
                            texture2d<half, access::write> outputImage [[texture(1)]],
                            ushort2 gridIndex [[thread_position_in_grid]]) {
  const ushort2 outputSize = ushort2(outputImage.get_width(), outputImage.get_height());
  if (gridIndex.x >= outputSize.x || gridIndex.y >= outputSize.y) {
    return;
  }

  ushort2 inputCoordinates = gridIndex / magnificationFactor;
  outputImage.write(inputImage.read(inputCoordinates), gridIndex.xy);
}

kernel void nearestNeighborArray(texture2d_array<half, access::read> inputImage [[texture(0)]],
                                 texture2d_array<half, access::write> outputImage [[texture(1)]],
                                 ushort3 gridIndex [[thread_position_in_grid]]) {
  const ushort2 outputSize = ushort2(outputImage.get_width(), outputImage.get_height());
  const ushort outputArrayLenght = outputImage.get_array_size();
  if (gridIndex.x >= outputSize.x || gridIndex.y >= outputSize.y ||
      gridIndex.z >= outputArrayLenght) {
    return;
  }

  ushort2 inputCoordinates = gridIndex.xy / magnificationFactor;
  outputImage.write(inputImage.read(inputCoordinates, gridIndex.z), gridIndex.xy, gridIndex.z);
}
