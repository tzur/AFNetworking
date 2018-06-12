// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#include <metal_stdlib>
using namespace metal;

/// Number of histogram entries, or "bins" for each channel.
constant ushort kHistogramBins [[function_constant(0)]];

/// Number of pixels in the input buffer provided to the kernel.
constant uint kInputSize [[function_constant(1)]];

/// Atomically increase the given \c bin at the given \c sharedWarpHistogram.
inline void increaseBin(threadgroup atomic_uint *sharedWarpHistogram, uint bin) {
  atomic_fetch_add_explicit(sharedWarpHistogram + bin, 1, memory_order_relaxed);
}

/// Computes the partial histogram for each threadgroup, such that each warp shares one histogram in
/// the threadgroup shared memory.
void computePartialHistograms(constant float3 *input, float3x3 transform,
                              float3 minRange, float3 maxRange, device uint3 *partialHistograms,
                              threadgroup atomic_uint *sharedHistogramR,
                              threadgroup atomic_uint *sharedHistogramG,
                              threadgroup atomic_uint *sharedHistogramB,
                              uint sharedBuffersLength, uint indexInThreadgroup,
                              uint threadgroupIndex, uint numThreadsPerThreadgroup,
                              uint numThreadgroups, uint warpSize) {
  // Histograms shared by each warp's threads.
  uint warpHistogramOffset = (indexInThreadgroup >> ctz(warpSize)) * kHistogramBins;
  threadgroup atomic_uint *sharedWarpHistogramR = sharedHistogramR + warpHistogramOffset;
  threadgroup atomic_uint *sharedWarpHistogramG = sharedHistogramG + warpHistogramOffset;
  threadgroup atomic_uint *sharedWarpHistogramB = sharedHistogramB + warpHistogramOffset;

  // Clear the shared memory used by the threadgroup.
  for (uint i = 0; i < (sharedBuffersLength / numThreadsPerThreadgroup) + 1; i++) {
    uint offset = indexInThreadgroup + i * numThreadsPerThreadgroup;
    if (offset < sharedBuffersLength) {
      atomic_store_explicit(sharedHistogramR + offset, 0, memory_order_relaxed);
      atomic_store_explicit(sharedHistogramG + offset, 0, memory_order_relaxed);
      atomic_store_explicit(sharedHistogramB + offset, 0, memory_order_relaxed);
    }
  }
  threadgroup_barrier(mem_flags::mem_threadgroup);

  // Iterate over the entire input, updating the histograms for each warp.
  float3 rangeLength = maxRange - minRange;
  for (uint i = threadgroupIndex * numThreadsPerThreadgroup + indexInThreadgroup; i < kInputSize;
       i += numThreadsPerThreadgroup * numThreadgroups) {
    float3 data = transform * input[i];
    float3 value = (data - minRange) / rangeLength;
    uint3 targetBin = clamp(uint3(value * kHistogramBins), uint3(0), uint3(kHistogramBins - 1));
    increaseBin(sharedWarpHistogramR, targetBin.r);
    increaseBin(sharedWarpHistogramG, targetBin.g);
    increaseBin(sharedWarpHistogramB, targetBin.b);
  }
  threadgroup_barrier(mem_flags::mem_threadgroup);

  // Merge the per-warp histograms into a threadgroup partial histogram.
  for (uint bin = indexInThreadgroup; bin < kHistogramBins; bin += numThreadsPerThreadgroup) {
    uint sumR = 0;
    uint sumG = 0;
    uint sumB = 0;

    for (uint i = 0; i < numThreadsPerThreadgroup / warpSize; i++) {
      uint offset = bin + i * kHistogramBins;
      sumR += atomic_load_explicit(sharedHistogramR + offset, memory_order_relaxed);
      sumG += atomic_load_explicit(sharedHistogramG + offset, memory_order_relaxed);
      sumB += atomic_load_explicit(sharedHistogramB + offset, memory_order_relaxed);
    }

    partialHistograms[threadgroupIndex * kHistogramBins + bin] = uint3(sumR, sumG, sumB);
  }
}

/// Maximum total threadgroup memory allocation of devices with 16KB limit, since in some iOS and
/// tvOS feature sets, the driver may consume up to 32 bytes of a device's total threadgroup memory.
constant uint kMaxThreadgroupMemoryLength16K = (1 << 14) - 32;

/// Maximum total threadgroup memory allocation of devices with 32KB limit, since in some iOS and
/// tvOS feature sets, the driver may consume up to 32 bytes of a device's total threadgroup memory.
constant uint kMaxThreadgroupMemoryLength32K = (1 << 15) - 32;

/// Computes the partial histogram for each threadgroup using \c 16KB of threadgroup shared memory,
/// such that each warp shares one histogram in the threadgroup shared memory.
kernel void computePartialHistograms16K(constant float3 *input [[buffer(0)]],
                                        constant float3x3 *transform [[buffer(1)]],
                                        constant float3 *rangeMin [[buffer(2)]],
                                        constant float3 *rangeMax [[buffer(3)]],
                                        device uint3 *partialHistograms [[buffer(4)]],
                                        uint indexInThreadgroup [[thread_index_in_threadgroup]],
                                        uint threadgroupIndex [[threadgroup_position_in_grid]],
                                        uint numThreadsPerThreadgroup [[threads_per_threadgroup]],
                                        uint numThreadgroups [[threadgroups_per_grid]],
                                        uint warpSize [[thread_execution_width]]) {
  constexpr uint kSharedBuffersLength = kMaxThreadgroupMemoryLength16K / 3 / sizeof(atomic_uint);
  threadgroup atomic_uint sharedHistogramR[kSharedBuffersLength];
  threadgroup atomic_uint sharedHistogramG[kSharedBuffersLength];
  threadgroup atomic_uint sharedHistogramB[kSharedBuffersLength];

  computePartialHistograms(input, *transform, *rangeMin, *rangeMax, partialHistograms,
                           sharedHistogramR, sharedHistogramG, sharedHistogramB,
                           kSharedBuffersLength, indexInThreadgroup, threadgroupIndex,
                           numThreadsPerThreadgroup, numThreadgroups, warpSize);
}

/// Computes the partial histogram for each threadgroup using \c 32KB of threadgroup shared memory,
/// such that each warp shares one histogram in the threadgroup shared memory.
kernel void computePartialHistograms32K(constant float3 *input [[buffer(0)]],
                                        constant float3x3 *transform [[buffer(1)]],
                                        constant float3 *rangeMin [[buffer(2)]],
                                        constant float3 *rangeMax [[buffer(3)]],
                                        device uint3 *partialHistograms [[buffer(4)]],
                                        uint indexInThreadgroup [[thread_index_in_threadgroup]],
                                        uint threadgroupIndex [[threadgroup_position_in_grid]],
                                        uint numThreadsPerThreadgroup [[threads_per_threadgroup]],
                                        uint numThreadgroups [[threadgroups_per_grid]],
                                        uint warpSize [[thread_execution_width]]) {
  constexpr uint kSharedBuffersLength = kMaxThreadgroupMemoryLength32K / 3 / sizeof(atomic_uint);
  threadgroup atomic_uint sharedHistogramR[kSharedBuffersLength];
  threadgroup atomic_uint sharedHistogramG[kSharedBuffersLength];
  threadgroup atomic_uint sharedHistogramB[kSharedBuffersLength];
  computePartialHistograms(input, *transform, *rangeMin, *rangeMax, partialHistograms,
                           sharedHistogramR, sharedHistogramG, sharedHistogramB,
                           kSharedBuffersLength, indexInThreadgroup, threadgroupIndex,
                           numThreadsPerThreadgroup, numThreadgroups, warpSize);
}

/// Merges the partial histograms into a single histogram, running a different threadgroup per each
/// histogram bin, adding the same bin counter from every partial histogram.
void mergeHistograms(constant uint3 *partialHistograms, uint partialHistogramsCount,
                     device uint3 *histogram, threadgroup uint3 *sharedSums,
                     uint indexInThreadgroup, uint threadgroupIndex) {
  sharedSums[indexInThreadgroup] = indexInThreadgroup < partialHistogramsCount ?
  partialHistograms[threadgroupIndex + indexInThreadgroup * kHistogramBins] : 0;

  // Reduction in shared memory.
  for (uint stride = partialHistogramsCount / 2; stride > 0; stride >>= 1) {
    threadgroup_barrier(mem_flags::mem_threadgroup);

    if (indexInThreadgroup < stride) {
      sharedSums[indexInThreadgroup] += sharedSums[indexInThreadgroup + stride];
    }
  }

  if (indexInThreadgroup == 0) {
    histogram[threadgroupIndex] = sharedSums[0];
  }
}

/// Merges \c 512 partial histograms into a single histogram, running a different threadgroup per
/// each histogram bin and adding the same bin counter from every partial histogram.
kernel void mergeHistograms512(constant uint3 *partialHistograms [[buffer(0)]],
                               device uint3 *histogram [[buffer(1)]],
                               uint index [[thread_position_in_grid]],
                               uint indexInThreadgroup [[thread_index_in_threadgroup]],
                               uint threadgroupIndex [[threadgroup_position_in_grid]]) {
  threadgroup uint3 shared[512];
  mergeHistograms(partialHistograms, 512, histogram, shared, indexInThreadgroup, threadgroupIndex);
}

/// Merges \c 1024 partial histograms into a single histogram, running a different threadgroup per
/// histogram bin and adding the same bin counter from every partial histogram.
kernel void mergeHistograms1024(constant uint3 *partialHistograms [[buffer(0)]],
                                device uint3 *histogram [[buffer(1)]],
                                uint index [[thread_position_in_grid]],
                                uint indexInThreadgroup [[thread_index_in_threadgroup]],
                                uint threadgroupIndex [[threadgroup_position_in_grid]]) {
  threadgroup uint3 shared[1024];
  mergeHistograms(partialHistograms, 1024, histogram, shared, indexInThreadgroup, threadgroupIndex);
}
