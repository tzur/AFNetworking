// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#include <metal_stdlib>

#include "PNKActivation.metal.h"
#include "PNKTemplatedIO.metal"

using namespace metal;

constant const ushort activationType [[function_constant(0)]];
constant const bool hasAlphaBuffer [[function_constant(1)]];
constant const bool hasBetaBuffer [[function_constant(2)]];

template <typename T, typename U>
void instanceNormAll(constant half4 *scale, constant half4 *shift, constant half4 *alpha,
                     constant half4 *beta, T inputImage, U outputImage, ushort2 gridIndex,
                     ushort arrayIndex, ushort threadIndex, ushort3 threadCount, ushort warpSize,
                     threadgroup float4 *threadgroupSum) {
  ushort width = inputImage.get_width();
  ushort height = inputImage.get_height();
  float pixelCount = width * height;
  const ushort totalThreadCount = threadCount.x * threadCount.y;

  threadgroupSum[threadIndex] = 0;
  for (ushort y = gridIndex.y; y < height; y += threadCount.y) {
    for (ushort x = gridIndex.x; x < width; x += threadCount.x) {
      threadgroupSum[threadIndex] += static_cast<float4>(lt::read(inputImage, uint2(x, y),
                                                                  arrayIndex)) / pixelCount;
    }
  }

  threadgroup_barrier(mem_flags::mem_threadgroup);

  if (threadIndex < warpSize) {
    for (ushort i = threadIndex + warpSize; i < totalThreadCount; i += warpSize) {
      threadgroupSum[threadIndex] += threadgroupSum[i];
    }
  }

  threadgroup_barrier(mem_flags::mem_threadgroup);

  if (threadIndex == 0) {
    float4 sum = 0.0;
    ushort accumulatorBoundry = min(ushort(warpSize), totalThreadCount);
    for (ushort i = 0; i < accumulatorBoundry; ++i) {
      sum += threadgroupSum[i];
    }
    threadgroupSum[0] = sum;
  }

  threadgroup_barrier(mem_flags::mem_threadgroup);

  const float4 mean = threadgroupSum[0];

  threadgroup_barrier(mem_flags::mem_threadgroup);

  threadgroupSum[threadIndex] = 0;
  for (ushort y = gridIndex.y; y < height; y += threadCount.y) {
    for (ushort x = gridIndex.x; x < width; x += threadCount.x) {
      float4 delta = static_cast<float4>(lt::read(inputImage, uint2(x, y), arrayIndex)) - mean;
      threadgroupSum[threadIndex] += delta * delta / pixelCount;
    }
  }

  threadgroup_barrier(mem_flags::mem_threadgroup);

  if (threadIndex < warpSize) {
    for (ushort i = threadIndex + warpSize; i < totalThreadCount; i += warpSize) {
      threadgroupSum[threadIndex] += threadgroupSum[i];
    }
  }

  threadgroup_barrier(mem_flags::mem_threadgroup);

  if (threadIndex == 0) {
    float4 sum = 0.0;
    ushort accumulatorBoundry = min(ushort(warpSize), totalThreadCount);
    for (ushort i = 0; i < accumulatorBoundry; ++i) {
      sum += threadgroupSum[i];
    }
    threadgroupSum[0] = 1.0 / sqrt(max(sum, float4(1e-5)) + 1e-5);
  }

  threadgroup_barrier(mem_flags::mem_threadgroup);

  const float4 inverseSigma = threadgroupSum[0];

  const float4 textureScale = static_cast<float4>(scale[arrayIndex]);
  const float4 textureShift = static_cast<float4>(shift[arrayIndex]);

  const float4 correctedScale = inverseSigma * textureScale;
  const float4 correctedShift = textureShift - mean * correctedScale;

  for (ushort y = gridIndex.y; y < height; y += threadCount.y) {
    for (ushort x = gridIndex.x; x < width; x += threadCount.x) {
      float4 floatInput = static_cast<float4>(lt::read(inputImage, uint2(x, y), arrayIndex));
      half4 scaled = static_cast<half4>(floatInput * correctedScale + correctedShift);
      half4 activated = pnk::ActivatedValue(scaled, activationType, alpha, beta, arrayIndex);
      lt::write(outputImage, activated, uint2(x, y), arrayIndex);
    }
  }
}

kernel void instanceNormArray(constant half4 *scale [[buffer(0)]],
                              constant half4 *shift [[buffer(1)]],
                              constant half4 *alpha [[buffer(2),
                                                      function_constant(hasAlphaBuffer)]],
                              constant half4 *beta [[buffer(3), function_constant(hasBetaBuffer)]],
                              texture2d_array<half, access::read> inputImage [[texture(0)]],
                              texture2d_array<half, access::write> outputImage [[texture(1)]],
                              ushort3 gridIndex [[thread_position_in_grid]],
                              ushort threadIndex [[thread_index_in_threadgroup]],
                              ushort3 threadCount [[threads_per_threadgroup]],
                              ushort warpSize [[thread_execution_width]]) {
  if (gridIndex.z >= outputImage.get_array_size()) {
    return;
  }

  constexpr ushort kMaxThreadsInGroup = 256;
  threadgroup float4 threadgroupSum[kMaxThreadsInGroup];

  instanceNormAll(scale, shift, alpha, beta, inputImage, outputImage, gridIndex.xy, gridIndex.z,
                  threadIndex, threadCount, warpSize, threadgroupSum);
}

kernel void instanceNorm(constant half4 *scale [[buffer(0)]],
                         constant half4 *shift [[buffer(1)]],
                         constant half4 *alpha [[buffer(2), function_constant(hasAlphaBuffer)]],
                         constant half4 *beta [[buffer(3), function_constant(hasBetaBuffer)]],
                         texture2d<half, access::read> inputImage [[texture(0)]],
                         texture2d<half, access::write> outputImage [[texture(1)]],
                         ushort3 gridIndex [[thread_position_in_grid]],
                         ushort threadIndex [[thread_index_in_threadgroup]],
                         ushort3 threadCount [[threads_per_threadgroup]],
                         ushort warpSize [[thread_execution_width]]) {
  constexpr ushort kMaxThreadsInGroup = 256;
  threadgroup float4 threadgroupSum[kMaxThreadsInGroup];

  instanceNormAll(scale, shift, alpha, beta, inputImage, outputImage, gridIndex.xy, 0,
                  threadIndex, threadCount, warpSize, threadgroupSum);
}
