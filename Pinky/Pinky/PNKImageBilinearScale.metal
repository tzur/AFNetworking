// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#include <metal_stdlib>

#include "PNKTypeDefinitions.h"

using namespace metal;

constexpr sampler s(filter::linear);

constexpr constant half4 RGBToYCoefficients = half4(0.299h, 0.587h, 0.114h, 0.0h);

kernel void bilinearScale(texture2d<half, access::sample> inputImage [[texture(0)]],
                          texture2d<half, access::write> outputImage [[texture(1)]],
                          constant float *inverseOutputSize [[buffer(0)]],
                          constant pnk::ColorTransformType *colorTransformType [[buffer(1)]],
                          uint2 gridIndex [[thread_position_in_grid]]) {
  if (gridIndex.x >= outputImage.get_width() || gridIndex.y >= outputImage.get_height()) {
    return;
  }

  float2 floatCoord(((float)gridIndex.x + 0.5) * inverseOutputSize[0],
                    ((float)gridIndex.y + 0.5) * inverseOutputSize[1]);
  half4 pixel = inputImage.sample(s, floatCoord);
  if (colorTransformType[0] == pnk::ColorTransformTypeYToRGBA) {
    pixel = half4(pixel.r, pixel.r, pixel.r, 1.0h);
  } else if (colorTransformType[0] == pnk::ColorTransformTypeRGBAToY) {
    half yValue = dot(pixel, RGBToYCoefficients);
    pixel = half4(yValue, yValue, yValue, 1.0h);
  }
  outputImage.write(pixel, gridIndex);
}
