// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#include <metal_stdlib>
using namespace metal;

/// Recent GPU families on iOS 11 support 1024 threads per threadgroup, combined with an increased
/// maximum threadgroup memory allocation that can allow increasing this number. This can be done
/// using templates but is currently not needed since in iOS 11 the MPS counterpart of this kernel
/// is used.
constant uint kMaxThreadsPerThreadGroup = 512;

/// Number of pixels in the given input buffer.
constant uint kInputSize [[function_constant(0)]];

/// Atomic exchange if the given \c candidate is less than \c current.
static void atomic_exchange_if_less(volatile device atomic_int *current, float candidate) {
  float val;
  do {
    val = *((device float *)current);
  } while ((candidate < val) &&
           !atomic_compare_exchange_weak_explicit(current, (thread int *)&val,
                                                  *((thread int *)&candidate),
                                                  memory_order_relaxed, memory_order_relaxed));
}

/// Atomic exchange if the given \c candidate is greater than \c current.
static void atomic_exchange_if_greater(volatile device atomic_int *current, float candidate) {
  float val;
  do {
    val = *((device float *)current);
  } while (candidate > val &&
           !atomic_compare_exchange_weak_explicit(current, (thread int *)&val,
                                                  *((thread int *)&candidate),
                                                  memory_order_relaxed, memory_order_relaxed));
}

kernel void resetMinMax(device float4 *minValues [[buffer(0)]],
                        device float4 *maxValues [[buffer(1)]],
                        uint index [[thread_position_in_grid]]) {
  minValues[index] = FLT_MAX;
  maxValues[index] = -FLT_MAX;
}

void reduceMinMaxInSharedMemory(threadgroup half3 *sharedMinValues,
                                threadgroup half3 *sharedMaxValues,
                                uint sharedValuesSize, uint index, ushort warpSize) {
  // Reduction in shared memory.
  for (uint stride = sharedValuesSize / 2; stride > 0; stride >>= 1) {
    if (index < stride) {
      sharedMinValues[index] = min(sharedMinValues[index], sharedMinValues[index + stride]);
      sharedMaxValues[index] = max(sharedMaxValues[index], sharedMaxValues[index + stride]);
    }

    if (stride > warpSize) {
      threadgroup_barrier(mem_flags::mem_threadgroup);
    } else {
      simdgroup_barrier(mem_flags::mem_none);
    }
  }
}

/// Finds the minimum and maximum pixel values per threadgroup in the given buffer after applying
/// the given 3x3 transformation to it in-situ.
/// Uses the optimizations described in http://developer.download.nvidia.com/compute/cuda/1.1-Beta/x86_website/projects/reduction/doc/reduction.pdf
kernel void findMinMaxPerThreadgroup(constant float3 *input [[buffer(0)]],
                                     constant float3x3 *transform [[buffer(1)]],
                                     device float3 *resultMinValues [[buffer(2)]],
                                     device float3 *resultMaxValues [[buffer(3)]],
                                     uint index [[thread_index_in_threadgroup]],
                                     uint threadgroupPosition [[threadgroup_position_in_grid]],
                                     uint threadCount [[threads_per_threadgroup]],
                                     ushort warpSize [[thread_execution_width]]) {
  threadgroup half3 sharedMinValues[kMaxThreadsPerThreadGroup];
  threadgroup half3 sharedMaxValues[kMaxThreadsPerThreadGroup];

  // It appears that this works properly in iOS 10 even without clamping the index at
  // kInputSize - 1, although from the Metal documenation non-uniform threadgroups were added only
  // in iOS 11. I Couldn't find any indication whether this is a non-issue when dealing with
  // MTLBuffers instead of MTLTextures, and decided it's safer to leave this clamping as a
  // precaution.
  uint offset = threadgroupPosition * (threadCount * 2) + index;
  float3 value = *transform * input[min(offset, kInputSize - 1)];
  float3 nextValue = *transform * input[min(offset + threadCount, kInputSize - 1)];

  sharedMinValues[index] = half3(min(value, nextValue));
  sharedMaxValues[index] = half3(max(value, nextValue));
  threadgroup_barrier(mem_flags::mem_threadgroup);

  reduceMinMaxInSharedMemory(sharedMinValues, sharedMaxValues,
                             kMaxThreadsPerThreadGroup, index, warpSize);

  if (index == 0) {
    resultMinValues[int(threadgroupPosition)] = float3(sharedMinValues[0]);
    resultMaxValues[int(threadgroupPosition)] = float3(sharedMaxValues[0]);
  }
}

/// Finds the minimum and maximum pixel values in the given buffers containing the minimum and
/// maximum values found per each threadgroup in the first part of the reduction.
kernel void findMinMax(constant float3 *minInputs [[buffer(0)]],
                       constant float3 *maxInputs [[buffer(1)]],
                       volatile device atomic_int *resultMin [[buffer(2)]],
                       volatile device atomic_int *resultMax [[buffer(3)]],
                       uint index [[thread_index_in_threadgroup]],
                       uint threadgroupPosition [[threadgroup_position_in_grid]],
                       uint threadCount [[threads_per_threadgroup]],
                       ushort warpSize [[thread_execution_width]]) {
  threadgroup half3 sharedMinValues[kMaxThreadsPerThreadGroup];
  threadgroup half3 sharedMaxValues[kMaxThreadsPerThreadGroup];

  // Boundary check is not necessary here since we know the number of elements is a power of 2.
  uint offset = threadgroupPosition * (threadCount * 2) + index;
  sharedMinValues[index] = half3(min(minInputs[offset], minInputs[offset + threadCount]));
  sharedMaxValues[index] = half3(max(maxInputs[offset], maxInputs[offset + threadCount]));
  threadgroup_barrier(mem_flags::mem_threadgroup);

  reduceMinMaxInSharedMemory(sharedMinValues, sharedMaxValues,
                             kMaxThreadsPerThreadGroup, index, warpSize);

  if (index == 0) {
    atomic_exchange_if_less(resultMin, sharedMinValues[0].r);
    atomic_exchange_if_less(resultMin + 1, sharedMinValues[0].g);
    atomic_exchange_if_less(resultMin + 2, sharedMinValues[0].b);
    atomic_exchange_if_greater(resultMax, sharedMaxValues[0].r);
    atomic_exchange_if_greater(resultMax + 1, sharedMaxValues[0].g);
    atomic_exchange_if_greater(resultMax + 2, sharedMaxValues[0].b);
  }
}

/// Applies a 3x3 transform on each pixel.
kernel void applyTransformOnBuffer(texture2d<float, access::write> output [[texture(0)]],
                                   constant float3 *input [[buffer(0)]],
                                   constant float3x3 *transform [[buffer(1)]],
                                   uint2 index [[thread_position_in_grid]]) {
  const uint width = output.get_width();
  if (index.x >= width || index.y >= output.get_height()) {
    return;
  }

  const float3 color = input[index.y * width + index.x];
  output.write(float4(*transform * color, 1.0), index);
}

/// Merges the result of \c MPSImageStatisticsMinAndMax on a single buffer into the global result
/// buffers.
kernel void mergeMinMax(texture2d<float, access::read> input [[texture(0)]],
                        device float3 *resultMin [[buffer(0)]],
                        device float3 *resultMax [[buffer(1)]]) {
  const float3 minCandidate = input.read(uint2(0, 0)).rgb;
  const float3 maxCandidate = input.read(uint2(1, 0)).rgb;
  *resultMin = min(*resultMin, minCandidate);
  *resultMax = max(*resultMax, maxCandidate);
}
