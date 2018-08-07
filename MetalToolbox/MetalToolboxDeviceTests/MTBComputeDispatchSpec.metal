// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#include <metal_stdlib>

using namespace metal;

kernel void additionBufferAndTexture(constant uchar *inputBuffer [[buffer(0)]],
                                     texture2d<half, access::read> inputImage [[texture(0)]],
                                     texture2d<half, access::write> outputImage [[texture(1)]],
                                     uint2 gridIndex [[thread_position_in_grid]]) {
  const uint2 outputSize = uint2(outputImage.get_width(), outputImage.get_height());
  if (any(gridIndex >= outputSize)) {
    return;
  }

  half4 inputA = half4(half(inputBuffer[0]) / 255.0h);
  half4 inputB = inputImage.read(gridIndex);
  half4 output = inputA + inputB;
  outputImage.write(output, gridIndex);
}

kernel void additionBuffer(constant uchar *inputBufferA [[buffer(0)]],
                           constant uchar *inputBufferB [[buffer(1)]],
                           device uchar *outputBuffer [[buffer(2)]],
                           uint gridIndex [[thread_position_in_grid]]) {
  outputBuffer[gridIndex] = inputBufferA[gridIndex] + inputBufferB[gridIndex];
}

kernel void additionSingle(texture2d<half, access::read> inputImageA [[texture(0)]],
                           texture2d<half, access::read> inputImageB [[texture(1)]],
                           texture2d<half, access::write> outputImage [[texture(2)]],
                           uint2 gridIndex [[thread_position_in_grid]]) {
  const uint2 outputSize = uint2(outputImage.get_width(), outputImage.get_height());
  if (any(gridIndex >= outputSize)) {
    return;
  }

  half4 inputA = inputImageA.read(gridIndex);
  half4 inputB = inputImageB.read(gridIndex);
  half4 output = inputA + inputB;
  outputImage.write(output, gridIndex);
}

kernel void additionArray(texture2d_array<half, access::read> inputImageA [[texture(0)]],
                          texture2d_array<half, access::read> inputImageB [[texture(1)]],
                          texture2d_array<half, access::write> outputImage [[texture(2)]],
                          uint3 gridIndex [[thread_position_in_grid]]) {
  const uint3 outputSize = uint3(outputImage.get_width(), outputImage.get_height(),
                                 outputImage.get_array_size());
  if (any(gridIndex >= outputSize)) {
    return;
  }

  half4 inputA = inputImageA.read(gridIndex.xy, gridIndex.z);
  half4 inputB = inputImageB.read(gridIndex.xy, gridIndex.z);
  half4 output = inputA + inputB;
  outputImage.write(output, gridIndex.xy, gridIndex.z);
}
