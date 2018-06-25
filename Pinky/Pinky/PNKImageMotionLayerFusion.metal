// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#include <metal_stdlib>

#include "PNKImageMotionLayerType.h"

using namespace metal;

constexpr sampler s(address::clamp_to_zero, filter::nearest);

kernel void layerFusion(texture2d<half, access::sample> inputSegmentationImage [[texture(0)]],
                        texture2d<half, access::read> skyDisplacementsImage [[texture(1)]],
                        texture2d<half, access::read> staticDisplacementsImage [[texture(2)]],
                        texture2d<half, access::read> treesDisplacementsImage [[texture(3)]],
                        texture2d<half, access::read> grassDisplacementsImage [[texture(4)]],
                        texture2d<half, access::read> waterDisplacementsImage [[texture(5)]],
                        texture2d<half, access::write> outputSegmentationImage [[texture(6)]],
                        texture2d<half, access::write> outputDisplacementsImage [[texture(7)]],
                        constant float *inverseOutputSize [[buffer(0)]],
                        uint2 gridIndex [[thread_position_in_grid]]) {
  const uint2 outputSize = uint2(outputSegmentationImage.get_width(),
                                 outputSegmentationImage.get_height());
  if (any(gridIndex >= outputSize)) {
    return;
  }

  half resultLayerIndex((half)pnk::ImageMotionLayerTypeNone / (half)255.0);
  half2 resultDisplacement(0.h);

  float2 floatCoord((float)gridIndex.x * inverseOutputSize[0],
                    (float)gridIndex.y * inverseOutputSize[1]);

  half4 displacement = skyDisplacementsImage.read(gridIndex);
  float2 displacedCoord = floatCoord + float2(displacement.x, displacement.y);

  half4 originalLayerIndex = inputSegmentationImage.sample(s, displacedCoord);
  if (originalLayerIndex.x == (half)pnk::ImageMotionLayerTypeSky / (half)255.0) {
    resultLayerIndex = (half)pnk::ImageMotionLayerTypeSky / (half)255.0;
    resultDisplacement = displacement.xy;
  }

  displacement = staticDisplacementsImage.read(gridIndex);
  displacedCoord = floatCoord + float2(displacement.x, displacement.y);
  originalLayerIndex = inputSegmentationImage.sample(s, displacedCoord);
  if (originalLayerIndex.x == (half)pnk::ImageMotionLayerTypeStatic / (half)255.0) {
    resultLayerIndex = (half)pnk::ImageMotionLayerTypeStatic / (half)255.0;
    resultDisplacement = displacement.xy;
  }

  displacement = treesDisplacementsImage.read(gridIndex);
  displacedCoord = floatCoord + float2(displacement.x, displacement.y);
  originalLayerIndex = inputSegmentationImage.sample(s, displacedCoord);
  if (originalLayerIndex.x == (half)pnk::ImageMotionLayerTypeTrees / (half)255.0) {
    resultLayerIndex = (half)pnk::ImageMotionLayerTypeTrees / (half)255.0;
    resultDisplacement = displacement.xy;
  }

  displacement = grassDisplacementsImage.read(gridIndex);
  displacedCoord = floatCoord + float2(displacement.x, displacement.y);
  originalLayerIndex = inputSegmentationImage.sample(s, displacedCoord);
  if (originalLayerIndex.x == (half)pnk::ImageMotionLayerTypeGrass / (half)255.0) {
    resultLayerIndex = (half)pnk::ImageMotionLayerTypeGrass / (half)255.0;
    resultDisplacement = displacement.xy;
  }

  displacement = waterDisplacementsImage.read(gridIndex);
  displacedCoord = floatCoord + float2(displacement.x, displacement.y);
  originalLayerIndex = inputSegmentationImage.sample(s, displacedCoord);
  if (originalLayerIndex.x == (half)pnk::ImageMotionLayerTypeWater / (half)255.0) {
    resultLayerIndex = (half)pnk::ImageMotionLayerTypeWater / (half)255.0;
    resultDisplacement = displacement.xy;
  }

  outputSegmentationImage.write(resultLayerIndex, gridIndex);
  outputDisplacementsImage.write(half4(resultDisplacement, 0, 0), gridIndex);
}
