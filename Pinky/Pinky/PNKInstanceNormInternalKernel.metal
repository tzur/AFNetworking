// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#include <metal_stdlib>

#include "PNKTemplatedIO.metal"

using namespace metal;

constant const bool hasPrelu [[function_constant(0)]];
constant const bool sharedPrelu [[function_constant(1)]];

template <typename T, typename U>
void instanceNormAll(constant half4 *scale [[buffer(0)]],
                     constant half4 *shift [[buffer(1)]],
                     constant half4 *preluWeights [[buffer(2), function_constant(hasPrelu)]],
                     T inputImage [[texture(0)]],
                     U outputImage [[texture(1)]],
                     ushort2 gridIndex, ushort arrayIndex, ushort threadIndex,
                     ushort3 threadCount, ushort warpSize,
                     threadgroup float4 *threadgroupSum) {
  ushort width = inputImage.get_width();
  ushort height = inputImage.get_height();
  float pixelCount = width * height;
  const ushort totalThreadCount = threadCount.x * threadCount.y;

  threadgroupSum[threadIndex] = 0;
  for (ushort y = gridIndex.y; y < height; y += threadCount.y) {
    for (ushort x = gridIndex.x; x < width; x += threadCount.x) {
      threadgroupSum[threadIndex] += static_cast<float4>(lt::read(inputImage, ushort2(x, y),
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
      float4 delta = static_cast<float4>(lt::read(inputImage, ushort2(x, y), arrayIndex)) - mean;
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

  half4 w;
  if (hasPrelu) {
    w = sharedPrelu ? half4(preluWeights[0][0]) : preluWeights[arrayIndex];
  }
  for (ushort y = gridIndex.y; y < height; y += threadCount.y) {
    for (ushort x = gridIndex.x; x < width; x += threadCount.x) {
      float4 floatInput = static_cast<float4>(lt::read(inputImage, ushort2(x, y), arrayIndex));
      half4 scaled = static_cast<half4>(floatInput * correctedScale + correctedShift);
      if (hasPrelu) {
        scaled = select(scaled * w, scaled, scaled > 0.0h);
      }
      lt::write(outputImage, scaled, ushort2(x, y), arrayIndex);
    }
  }
}

kernel void instanceNormArray(constant half4 *scale [[buffer(0)]],
                              constant half4 *shift [[buffer(1)]],
                              constant half4 *preluWeights [[buffer(2),
                                                             function_constant(hasPrelu)]],
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

  instanceNormAll(scale, shift, preluWeights, inputImage, outputImage, gridIndex.xy, gridIndex.z,
                  threadIndex, threadCount, warpSize, threadgroupSum);
}

kernel void instanceNorm(constant half4 *scale [[buffer(0)]],
                         constant half4 *shift [[buffer(1)]],
                         constant half4 *preluWeights [[buffer(2), function_constant(hasPrelu)]],
                         texture2d<half, access::read> inputImage [[texture(0)]],
                         texture2d<half, access::write> outputImage [[texture(1)]],
                         ushort3 gridIndex [[thread_position_in_grid]],
                         ushort threadIndex [[thread_index_in_threadgroup]],
                         ushort3 threadCount [[threads_per_threadgroup]],
                         ushort warpSize [[thread_execution_width]]) {
  constexpr ushort kMaxThreadsInGroup = 256;
  threadgroup float4 threadgroupSum[kMaxThreadsInGroup];

  instanceNormAll(scale, shift, preluWeights, inputImage, outputImage, gridIndex.xy, 0,
                  threadIndex, threadCount, warpSize, threadgroupSum);
}
