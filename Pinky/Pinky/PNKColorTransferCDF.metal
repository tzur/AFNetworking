// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#include <metal_stdlib>
using namespace metal;

/// Maximum number of bins supported by the kernel.
constant ushort kMaxSupportedHistogramBins = 1024;

/// Actual number of histogram entries, or "bins" for each channel.
constant ushort kHistogramBins [[function_constant(0)]];

/// Ratio between the number of samples in the inverse CDF and CDF, in order to achieve a
/// sufficiently close approximate of the inverse function.
constant ushort kInverseCDFScaleFactor [[function_constant(1)]];

/// Channel to use minimum and maximum values of when calculating the approximate inverse CDF.
constant ushort kChannel [[function_constant(2)]];

/// Size of the kernel used for smoothing the PDF. Must be odd.
constant ushort kPDFSmoothingKernelSize [[function_constant(3)]];

/// Calculates the pdf for each channel in the provided multi-channel \c histogram buffer, and
/// smoothing it using the kernel provided in \c pdfSmoothingKernel buffer.
kernel void calculatePDF(constant uint3 *histogram [[buffer(0)]],
                         constant float *pdfSmoothingKernel [[buffer(1)]],
                         device float3 *pdf [[buffer(2)]],
                         uint index [[thread_position_in_grid]],
                         uint indexInThreadgroup [[thread_index_in_threadgroup]],
                         uint numThreadsPerThreadgroup [[threads_per_threadgroup]]) {
  threadgroup uint3 sharedHistogram[kMaxSupportedHistogramBins];
  for (uint i = indexInThreadgroup; i < kHistogramBins; i += numThreadsPerThreadgroup) {
    sharedHistogram[i] = histogram[i];
  }
  threadgroup_barrier(mem_flags::mem_threadgroup);

  uint3 totalPixels = 0;
  for (ushort i = 0; i < kHistogramBins; ++i) {
    totalPixels += sharedHistogram[i];
  }
  float3 totalPixelsFloat = float3(totalPixels);

  float3 sum = float3(0);
  for (int i = 0; i < kPDFSmoothingKernelSize; ++i) {
    int offset = int(index) + i - kPDFSmoothingKernelSize / 2;
    float3 value = (offset >= 0 && offset < kHistogramBins) ?
        float3(sharedHistogram[offset]) / totalPixelsFloat : float3(0);
    sum += (value * float3(pdfSmoothingKernel[i]));
  }

  pdf[index] = sum;
}

/// Calculates the cdf for each channel in the provided multi-channel \c pdf buffer.
/// Single threaded due to small computation costs.
kernel void calculateCDF(constant float3 *pdf [[buffer(0)]],
                         device float *cdfR [[buffer(1)]],
                         device float *cdfG [[buffer(2)]],
                         device float *cdfB [[buffer(3)]]) {
  float3 value = float3(0);
  for (ushort i = 0; i < kHistogramBins; ++i) {
    value += pdf[i];
    cdfR[i] = value.r;
    cdfG[i] = value.g;
    cdfB[i] = value.b;
  }
}

/// Calculates the approximate inverse of the provided \c cdf representing uniformly sized bins
/// between \c minValue and \c maxValue. Total number of threads should match the total size of the
/// \c inverseCDF buffer, which should be <tt>kHistogramBins * kInverseCDFScaleFactor</tt>.
kernel void calculateInverseCDF(constant float *cdf [[buffer(0)]],
                                constant float *minValue [[buffer(1)]],
                                constant float *maxValue [[buffer(2)]],
                                device float *inverseCDF [[buffer(3)]],
                                uint index [[thread_position_in_grid]],
                                uint indexInThreadgroup [[thread_index_in_threadgroup]],
                                uint numThreadsPerThreadgroup [[threads_per_threadgroup]]) {
  const uint targetLength = kHistogramBins * kInverseCDFScaleFactor;

  // Read entire cdf to the faster shared memory.
  threadgroup float sharedCDF[kMaxSupportedHistogramBins];
  for (uint i = indexInThreadgroup; i < kHistogramBins; i += numThreadsPerThreadgroup) {
      sharedCDF[i] = cdf[i];
  }
  threadgroup_barrier(mem_flags::mem_threadgroup);

  if (index < targetLength) {
    float2 range = float2(minValue[kChannel], maxValue[kChannel]);
    float rangeLength = range.y - range.x;

    // Mix is needed instead of 'v = index / float(targetLength - 1)' due to precision issues.
    float v = mix(index / float(targetLength - 1), 1.0, float(targetLength - 1 == index));

    bool found = false;
    float minIndex = float(kHistogramBins) - 1.0;
    for (ushort j = 0; j < kHistogramBins && !found; ++j) {
      if (sharedCDF[j] > v) {
        found = true;
        if (j == 0) {
          minIndex = float(j);
        } else {
          float a = sharedCDF[j - 1];
          float b = sharedCDF[j];
          float alpha = (v - a) / (b - a);
          minIndex = float(j) - 1.0 + alpha;
        }
      }
    }

    float inverseIndex = minIndex / (float(kHistogramBins) - 1.0);
    inverseCDF[index] = range.x + inverseIndex * rangeLength;
  }
}
