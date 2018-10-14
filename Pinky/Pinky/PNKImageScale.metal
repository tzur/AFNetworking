// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#include <metal_stdlib>

#include "PNKTypeDefinitions.h"

using namespace metal;

constexpr sampler linearSampler(filter::linear, coord::pixel);
constexpr sampler nearestNeighborSampler(filter::nearest, coord::pixel);

constexpr constant half4 RGBToYCoefficients = half4(0.299h, 0.587h, 0.114h, 0.0h);

inline half4 colorTransform(half4 pixel, pnk::ColorTransformType colorTransformType) {
  if (colorTransformType == pnk::ColorTransformTypeYToRGBA) {
    return half4(pixel.r, pixel.r, pixel.r, 1.0h);
  } else if (colorTransformType == pnk::ColorTransformTypeRGBAToY) {
    half yValue = dot(pixel, RGBToYCoefficients);
    return half4(yValue, yValue, yValue, 1.0h);
  } else {
    return pixel;
  }
}

kernel void bilinearScale(texture2d<half, access::sample> inputImage [[texture(0)]],
                          texture2d<half, access::write> outputImage [[texture(1)]],
                          constant pnk::Rect2f *inputRectangle [[buffer(0)]],
                          constant pnk::Rect2ui *outputRectangle [[buffer(1)]],
                          constant float2 *outputRectangleInverseSize [[buffer(2)]],
                          constant pnk::ColorTransformType *colorTransformType [[buffer(3)]],
                          uint2 gridIndex [[thread_position_in_grid]]) {
  if (any(gridIndex >= outputRectangle->size)) {
    return;
  }

  float2 relativeCoordinate = (float2(0.5, 0.5) + (float2)gridIndex) *
      outputRectangleInverseSize[0];

  float2 inputCoordinate = inputRectangle->origin + inputRectangle->size * relativeCoordinate;

  half4 pixel = inputImage.sample(linearSampler, inputCoordinate);
  pixel = colorTransform(pixel, colorTransformType[0]);

  uint2 outputCoordinate = outputRectangle->origin + gridIndex;
  outputImage.write(pixel, outputCoordinate);
}

kernel void nearestNeighborScale(texture2d<half, access::sample> inputImage [[texture(0)]],
                                 texture2d<half, access::write> outputImage [[texture(1)]],
                                 constant pnk::Rect2f *inputRectangle [[buffer(0)]],
                                 constant pnk::Rect2ui *outputRectangle [[buffer(1)]],
                                 constant float2 *outputRectangleInverseSize [[buffer(2)]],
                                 constant pnk::ColorTransformType *colorTransformType [[buffer(3)]],
                                 uint2 gridIndex [[thread_position_in_grid]]) {
  if (any(gridIndex >= outputRectangle->size)) {
    return;
  }

  float2 relativeCoordinate = (float2)gridIndex * outputRectangleInverseSize[0];

  float2 inputCoordinate = inputRectangle->origin + inputRectangle->size * relativeCoordinate;

  half4 pixel = inputImage.sample(nearestNeighborSampler, inputCoordinate);
  pixel = colorTransform(pixel, colorTransformType[0]);

  uint2 outputCoordinate = outputRectangle->origin + gridIndex;
  outputImage.write(pixel, outputCoordinate);
}
