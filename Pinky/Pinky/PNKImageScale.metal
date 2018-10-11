// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#include <metal_stdlib>

#include "PNKTypeDefinitions.h"

using namespace metal;

constexpr sampler s(filter::linear);

constexpr constant half4 RGBToYCoefficients = half4(0.299h, 0.587h, 0.114h, 0.0h);

kernel void bilinearScale(texture2d<half, access::sample> inputImage [[texture(0)]],
                          texture2d<half, access::write> outputImage [[texture(1)]],
                          constant pnk::Rect2f *inputRectangle [[buffer(0)]],
                          constant pnk::Rect2ui *outputRectangle [[buffer(1)]],
                          constant float2 *inputTextureInverseSize [[buffer(2)]],
                          constant float2 *outputRectangleInverseSize [[buffer(3)]],
                          constant pnk::ColorTransformType *colorTransformType [[buffer(4)]],
                          uint2 gridIndex [[thread_position_in_grid]]) {
  if (any(gridIndex >= outputRectangle->size)) {
    return;
  }

  float2 relativeCoordinate = (float2(0.5, 0.5) + (float2)gridIndex) *
      outputRectangleInverseSize[0];

  float2 inputCoordinate = (inputRectangle->origin + inputRectangle->size * relativeCoordinate) *
      inputTextureInverseSize[0];

  half4 pixel = inputImage.sample(s, inputCoordinate);

  if (colorTransformType[0] == pnk::ColorTransformTypeYToRGBA) {
    pixel = half4(pixel.r, pixel.r, pixel.r, 1.0h);
  } else if (colorTransformType[0] == pnk::ColorTransformTypeRGBAToY) {
    half yValue = dot(pixel, RGBToYCoefficients);
    pixel = half4(yValue, yValue, yValue, 1.0h);
  }

  uint2 outputCoordinate = outputRectangle->origin + gridIndex;
  outputImage.write(pixel, outputCoordinate);
}
