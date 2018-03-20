// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#include <metal_stdlib>

#include "PNKTypeDefinitions.h"
#include "PNKTemplatedIO.metal"

using namespace metal;
using namespace pnk;

const constant ushort2 shiftX(1, 0);
const constant ushort2 shiftY(0, 1);
const constant ushort2 shiftXY(1, 1);

constexpr sampler bilinearSampler(filter::linear);

template <typename U, typename V>
void nearestNeighbor(U inputImage, V outputImage, ushort2 gridIndex, ushort arrayIndex) {
  const ushort2 inputSize = ushort2(inputImage.get_width(), inputImage.get_height());
  if (gridIndex.x >= inputSize.x || gridIndex.y >= inputSize.y) {
    return;
  }

  half4 pixel = lt::read(inputImage, gridIndex, arrayIndex);

  ushort2 outputCoordinates = gridIndex * 2;

  lt::write(outputImage, pixel, outputCoordinates, arrayIndex);
  lt::write(outputImage, pixel, outputCoordinates + shiftX, arrayIndex);
  lt::write(outputImage, pixel, outputCoordinates + shiftY, arrayIndex);
  lt::write(outputImage, pixel, outputCoordinates + shiftXY, arrayIndex);
}

kernel void nearestNeighborSingle(texture2d<half, access::read> inputImage [[texture(0)]],
                                  texture2d<half, access::write> outputImage [[texture(1)]],
                                  ushort2 gridIndex [[thread_position_in_grid]]) {
  nearestNeighbor(inputImage, outputImage, gridIndex, 0);
}

kernel void nearestNeighborArray(texture2d_array<half, access::read> inputImage [[texture(0)]],
                                 texture2d_array<half, access::write> outputImage [[texture(1)]],
                                 ushort3 gridIndex [[thread_position_in_grid]]) {
  if (gridIndex.z >= outputImage.get_array_size()) {
    return;
  }
  nearestNeighbor(inputImage, outputImage, gridIndex.xy, gridIndex.z);
}

template <typename U, typename V>
void bilinear(U inputImage, V outputImage, ushort2 gridIndex, ushort arrayIndex) {
  const ushort2 inputSize = ushort2(inputImage.get_width(), inputImage.get_height());
  if (gridIndex.x >= inputSize.x || gridIndex.y >= inputSize.y) {
    return;
  }

  ushort inputCoordX0 = gridIndex.x;
  ushort inputCoordX1 = min(inputCoordX0 + 1, inputSize.x - 1);

  ushort inputCoordY0 = gridIndex.y;
  ushort inputCoordY1 = min(inputCoordY0 + 1, inputSize.y - 1);

  half4 pixel00 = lt::read(inputImage, ushort2(inputCoordX0, inputCoordY0), arrayIndex);
  half4 pixel10 = lt::read(inputImage, ushort2(inputCoordX1, inputCoordY0), arrayIndex);
  half4 pixel01 = lt::read(inputImage, ushort2(inputCoordX0, inputCoordY1), arrayIndex);
  half4 pixel11 = lt::read(inputImage, ushort2(inputCoordX1, inputCoordY1), arrayIndex);

  ushort2 outputCoordinates = gridIndex * 2;

  lt::write(outputImage, pixel00, outputCoordinates, arrayIndex);
  lt::write(outputImage, 0.5 * (pixel00 + pixel10), outputCoordinates + shiftX, arrayIndex);
  lt::write(outputImage, 0.5 * (pixel00 + pixel01), outputCoordinates + shiftY, arrayIndex);
  lt::write(outputImage, 0.25 * (pixel00 + pixel10 + pixel01 + pixel11),
            outputCoordinates + shiftXY, arrayIndex);
}

kernel void bilinearSingle(texture2d<half, access::read> inputImage [[texture(0)]],
                           texture2d<half, access::write> outputImage [[texture(1)]],
                           ushort2 gridIndex [[thread_position_in_grid]]) {
  bilinear(inputImage, outputImage, gridIndex, 0);
}

kernel void bilinearArray(texture2d_array<half, access::read> inputImage [[texture(0)]],
                          texture2d_array<half, access::write> outputImage [[texture(1)]],
                          ushort3 gridIndex [[thread_position_in_grid]]) {
  if (gridIndex.z >= outputImage.get_array_size()) {
    return;
  }
  bilinear(inputImage, outputImage, gridIndex.xy, gridIndex.z);
}

template <typename U, typename V>
void bilinearAligned(U inputImage, V outputImage,
                     constant SamplingCoefficients *samplingCoefficients, ushort2 gridIndex,
                     ushort arrayIndex) {
  if (gridIndex.x >= outputImage.get_width() || gridIndex.y >= outputImage.get_height()) {
    return;
  }

  float2 samplingScale(samplingCoefficients->scaleX, samplingCoefficients->scaleY);
  float2 samplingBias(samplingCoefficients->biasX, samplingCoefficients->biasY);
  float2 normalizedCoordinates = (float2)gridIndex * samplingScale + samplingBias;

  half4 pixel = lt::sample(inputImage, bilinearSampler, normalizedCoordinates, arrayIndex);

  lt::write(outputImage, pixel, gridIndex, arrayIndex);
}

kernel void bilinearAlignedSingle(texture2d<half, access::sample> inputImage [[texture(0)]],
                                  texture2d<half, access::write> outputImage [[texture(1)]],
                                  constant SamplingCoefficients *samplingCoefficients [[buffer(0)]],
                                  ushort2 gridIndex [[thread_position_in_grid]]) {
  bilinearAligned(inputImage, outputImage, samplingCoefficients, gridIndex, 0);
}

kernel void bilinearAlignedArray(texture2d_array<half, access::sample> inputImage [[texture(0)]],
                                 texture2d_array<half, access::write> outputImage [[texture(1)]],
                                 constant SamplingCoefficients *samplingCoefficients [[buffer(0)]],
                                 ushort3 gridIndex [[thread_position_in_grid]]) {
  if (gridIndex.z >= outputImage.get_array_size()) {
    return;
  }
  bilinearAligned(inputImage, outputImage, samplingCoefficients, gridIndex.xy, gridIndex.z);
}
