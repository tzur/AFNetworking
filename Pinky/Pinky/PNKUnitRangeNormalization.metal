// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#include <metal_stdlib>

using namespace metal;

kernel void fullRescale(texture2d<half, access::read> inputImage [[texture(0)]],
                        texture2d<half, access::write> outputImage [[texture(1)]],
                        ushort2 gridIndex [[thread_position_in_grid]],
                        ushort threadIndex [[thread_index_in_threadgroup]],
                        ushort2 threadCount [[threads_per_threadgroup]],
                        ushort warpSize [[thread_execution_width]]) {
  constexpr ushort kMaxThreadsInGroup = 512;
  threadgroup half4 threadgroupMin[kMaxThreadsInGroup];
  threadgroup half4 threadgroupMax[kMaxThreadsInGroup];

  ushort width = inputImage.get_width();
  ushort height = inputImage.get_height();
  const ushort totalThreadCount = threadCount.x * threadCount.y;

  threadgroupMin[threadIndex] = numeric_limits<half>::max();
  threadgroupMax[threadIndex] = -numeric_limits<half>::max();
  for (ushort y = gridIndex.y; y < height; y += threadCount.y) {
    for (ushort x = gridIndex.x; x < width; x += threadCount.x) {
      auto pixel = inputImage.read(uint2(x, y));
      threadgroupMin[threadIndex] = min(pixel, threadgroupMin[threadIndex]);
      threadgroupMax[threadIndex] = max(pixel, threadgroupMax[threadIndex]);
    }
  }

  threadgroup_barrier(mem_flags::mem_threadgroup);

  if (threadIndex < warpSize) {
    for (ushort i = threadIndex + warpSize; i < totalThreadCount; i += warpSize) {
      threadgroupMin[threadIndex] = min(threadgroupMin[i], threadgroupMin[threadIndex]);
      threadgroupMax[threadIndex] = max(threadgroupMax[i], threadgroupMax[threadIndex]);
    }
  }

  simdgroup_barrier(mem_flags::mem_threadgroup);

  if (threadIndex == 0) {
    ushort accumulatorBoundary = min(ushort(warpSize), totalThreadCount);
    for (ushort i = 0; i < accumulatorBoundary; ++i) {
      threadgroupMin[0] = min(threadgroupMin[i], threadgroupMin[0]);
      threadgroupMax[0] = max(threadgroupMax[i], threadgroupMax[0]);
    }
  }

  threadgroup_barrier(mem_flags::mem_threadgroup);

  const half4 globalMin = threadgroupMin[0];
  const half4 globalMax = threadgroupMax[0];
  const half4 scale = 1.h / (globalMax - globalMin);

  for (ushort y = gridIndex.y; y < height; y += threadCount.y) {
    for (ushort x = gridIndex.x; x < width; x += threadCount.x) {
      auto pixel = inputImage.read(uint2(x, y));
      pixel = (pixel - globalMin) * scale;
      outputImage.write(pixel, uint2(x, y));
    }
  }
}

kernel void rescaleWithMinAndMax(texture2d<half, access::read> inputImage  [[texture(0)]],
                                 texture2d<half, access::read> minMaxImage [[texture(1)]],
                                 texture2d<half, access::write> outputImage [[texture(2)]],
                                 ushort2 gridIndex [[thread_position_in_grid]]) {
  auto globalMin = minMaxImage.read(ushort2(0, 0));
  auto globalMax = minMaxImage.read(ushort2(1, 0));
  half4 scale = 1.h / (globalMax - globalMin);

  auto pixel = inputImage.read(gridIndex);
  pixel = (pixel - globalMin) * scale;
  outputImage.write(pixel, gridIndex);
}
