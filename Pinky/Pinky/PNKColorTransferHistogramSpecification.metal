// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#include <metal_stdlib>
using namespace metal;

/// Number of bins in the histograms the input CDF and reference inverse CDF were dervied from.
constant ushort kHistogramBins [[function_constant(0)]];

/// Damping factor for progress of each iteration towards the reference. Lower values yield smaller
/// steps towards the reference's palette in each iteration, but increase the chance of convergence.
/// Must be in range <tt>[0, 1]</tt>, default is \c 0.2.
constant float kDampingFactor [[function_constant(1)]];

/// Ratio between the number of samples in the inverse CDF and CDF, in order to achieve a
/// sufficiently close approximate of the inverse function.
constant ushort kInverseCDFScaleFactor [[function_constant(2)]];

// Interpolate using lookup table, see documentation of vDSP_vtabi in Accelerate/vDSP.h.
inline float interpolate(float value, float scale, float offset,
                         constant float *lut, uint lutSize) {
  const uint lutLast = lutSize - 1;
  float p = scale * value + offset;
  float a = float(p < 0);
  float b = float(p >= 0 && p < lutLast);
  float c = float(p >= float(lutLast));

  p = clamp(p, 0.0, float(lutLast));
  float q = trunc(p);
  float r = p - q;
  return a * lut[0] + b * mix(lut[uint(q)], lut[min(uint(q) + 1, lutLast)], r) + c * lut[lutLast];
}

/// Performs histogram specification on every pixel in the \c input buffer in the basis given in
/// \c transform.
kernel void histogramSpecificationBuffer(device float3 *input [[buffer(0)]],
                                         constant float3x3 *transform [[buffer(1)]],
                                         constant float3 *minValue [[buffer(2)]],
                                         constant float3 *maxValue [[buffer(3)]],
                                         constant float *inputCDFR [[buffer(4)]],
                                         constant float *inputCDFG [[buffer(5)]],
                                         constant float *inputCDFB [[buffer(6)]],
                                         constant float *referenceInverseCDFR [[buffer(7)]],
                                         constant float *referenceInverseCDFG [[buffer(8)]],
                                         constant float *referenceInverseCDFB [[buffer(9)]],
                                         uint index [[thread_position_in_grid]]) {
  const uint referenceCDFSize = kHistogramBins * kInverseCDFScaleFactor;

  float3 minRange = *minValue;
  float3 maxRange = *maxValue;
  float3 rangeLength = maxRange - minRange;

  // Change basis to the given orthogonal basis.
  float3 inputValue = input[index];
  float3 value = *transform * inputValue;

  // First step of histogram specification: x -> input_cdf(x).
  float3 srcScale = float3(kHistogramBins - 1) / rangeLength;
  float3 srcOffset = -minRange * srcScale;
  float srcCDFValueR = interpolate(value.r, srcScale.r, srcOffset.r, inputCDFR, kHistogramBins);
  float srcCDFValueG = interpolate(value.g, srcScale.g, srcOffset.g, inputCDFG, kHistogramBins);
  float srcCDFValueB = interpolate(value.b, srcScale.b, srcOffset.b, inputCDFB, kHistogramBins);

  // Second step of histogram specification: input_cdf(x) -> reference_inverse_cdf(input_cdf(x)).
  float refScale = float(referenceCDFSize - 1);
  float refOffset = 0.0;
  float a = interpolate(srcCDFValueR, refScale, refOffset, referenceInverseCDFR, referenceCDFSize);
  float b = interpolate(srcCDFValueG, refScale, refOffset, referenceInverseCDFG, referenceCDFSize);
  float c = interpolate(srcCDFValueB, refScale, refOffset, referenceInverseCDFB, referenceCDFSize);

  // Change basis back to RGB.
  float3 adjustedValue = float3(a, b, c) * (*transform);

  // Apply the damping factor and write the result.
  input[index] = mix(inputValue, adjustedValue, kDampingFactor);
}
