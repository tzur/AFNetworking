// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#include <metal_stdlib>

#import "PNKColorTransformTypes.h"

using namespace metal;

constexpr sampler s(filter::linear);

kernel void bilinearScale(texture2d<half, access::sample> inputImage [[texture(0)]],
                          texture2d<half, access::write> outputImage [[texture(1)]],
                          constant float *inverseOutputSize [[buffer(0)]],
                          constant pnk::ColorTransformType *colorTransformType [[buffer(1)]],
                          ushort2 gridIndex [[thread_position_in_grid]]) {
  if (gridIndex.x >= outputImage.get_width() || gridIndex.y >= outputImage.get_height()) {
    return;
  }

  float2 floatCoord(((float)gridIndex.x + 0.5) * inverseOutputSize[0],
                    ((float)gridIndex.y + 0.5) * inverseOutputSize[1]);
  half4 pixel = inputImage.sample(s, floatCoord);
  if (colorTransformType[0] == pnk::ColorTransformTypeYToRGBA) {
    pixel = half4(pixel.r, pixel.r, pixel.r, 1.0h);
  }
  outputImage.write(pixel, gridIndex);
}
