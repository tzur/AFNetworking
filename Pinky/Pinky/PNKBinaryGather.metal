// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#include <metal_stdlib>

#include "PNKTemplatedIO.metal"

using namespace metal;

constant ushort primaryFeatureChannelIndicesSize [[function_constant(0)]];
constant ushort secondaryFeatureChannelIndicesSize [[function_constant(1)]];
constant ushort outputFeatureChannels = primaryFeatureChannelIndicesSize +
    secondaryFeatureChannelIndicesSize;

template <typename U, typename V, typename W>
void binaryGather(U inputImageA, V inputImageB, W outputImage,
                  constant ushort *primaryFeatureChannelIndices,
                  constant ushort *secondaryFeatureChannelIndices,
                  uint2 gridIndex [[thread_position_in_grid]]) {
  if (gridIndex.x >= outputImage.get_width() || gridIndex.y >= outputImage.get_height()) {
    return;
  }

  half4 pixel(0.0);

  bool sampledCurrentImage = false;
  ushort lastSampledChunk;
  half4 lastSampledChunkValue(0.0);

  for (ushort outputChannel = 0; outputChannel < primaryFeatureChannelIndicesSize;
       ++outputChannel) {
    ushort inputChannel = primaryFeatureChannelIndices[outputChannel];
    ushort inputChunk = inputChannel / 4;
    half4 inputChunkValue = (sampledCurrentImage && (inputChunk == lastSampledChunk)) ?
        lastSampledChunkValue : lt::read(inputImageA, gridIndex, inputChunk);

    sampledCurrentImage = true;
    lastSampledChunk = inputChunk;
    lastSampledChunkValue = inputChunkValue;

    pixel[outputChannel % 4] = inputChunkValue[inputChannel % 4];

    if (outputChannel % 4 == 3) {
      lt::write(outputImage, pixel, gridIndex, outputChannel / 4, 0);
      pixel = 0.0;
    }
  }

  sampledCurrentImage = false;

  for (ushort outputChannel = primaryFeatureChannelIndicesSize;
       outputChannel < outputFeatureChannels; ++outputChannel) {
    ushort inputChannel= secondaryFeatureChannelIndices[outputChannel -
                                                        primaryFeatureChannelIndicesSize];
    ushort inputChunk = inputChannel / 4;
    half4 inputChunkValue = (sampledCurrentImage && (inputChunk == lastSampledChunk)) ?
        lastSampledChunkValue : lt::read(inputImageB, gridIndex, inputChunk);

    sampledCurrentImage = true;
    lastSampledChunk = inputChunk;
    lastSampledChunkValue = inputChunkValue;

    pixel[outputChannel % 4] = inputChunkValue[inputChannel % 4];

    if (outputChannel % 4 == 3 || outputChannel == outputFeatureChannels - 1) {
      lt::write(outputImage, pixel, gridIndex, outputChannel / 4, 0);
      pixel = 0.0;
    }
  }
}

kernel void gatherSingleAndSingleToSingle(
    texture2d<half, access::read> inputImageA [[texture(0)]],
    texture2d<half, access::read> inputImageB [[texture(1)]],
    texture2d<half, access::write> outputImage [[texture(2)]],
    constant ushort *primaryFeatureChannelIndices [[buffer(0)]],
    constant ushort *secondaryFeatureChannelIndices [[buffer(1)]],
    uint2 gridIndex [[thread_position_in_grid]]) {
  binaryGather(inputImageA, inputImageB, outputImage, primaryFeatureChannelIndices,
               secondaryFeatureChannelIndices, gridIndex);
}

kernel void gatherSingleAndSingleToArray(
    texture2d<half, access::read> inputImageA [[texture(0)]],
    texture2d<half, access::read> inputImageB [[texture(1)]],
    texture2d_array<half, access::write> outputImage [[texture(2)]],
    constant ushort *primaryFeatureChannelIndices [[buffer(0)]],
    constant ushort *secondaryFeatureChannelIndices [[buffer(1)]],
    uint2 gridIndex [[thread_position_in_grid]]) {
  binaryGather(inputImageA, inputImageB, outputImage, primaryFeatureChannelIndices,
               secondaryFeatureChannelIndices, gridIndex);
}

kernel void gatherSingleAndArrayToSingle(
    texture2d<half, access::read> inputImageA [[texture(0)]],
    texture2d_array<half, access::read> inputImageB [[texture(1)]],
    texture2d<half, access::write> outputImage [[texture(2)]],
    constant ushort *primaryFeatureChannelIndices [[buffer(0)]],
    constant ushort *secondaryFeatureChannelIndices [[buffer(1)]],
    uint2 gridIndex [[thread_position_in_grid]]) {
  binaryGather(inputImageA, inputImageB, outputImage, primaryFeatureChannelIndices,
               secondaryFeatureChannelIndices, gridIndex);
}

kernel void gatherSingleAndArrayToArray(
    texture2d<half, access::read> inputImageA [[texture(0)]],
    texture2d_array<half, access::read> inputImageB [[texture(1)]],
    texture2d_array<half, access::write> outputImage [[texture(2)]],
    constant ushort *primaryFeatureChannelIndices [[buffer(0)]],
    constant ushort *secondaryFeatureChannelIndices [[buffer(1)]],
    uint2 gridIndex [[thread_position_in_grid]]) {
  binaryGather(inputImageA, inputImageB, outputImage, primaryFeatureChannelIndices,
               secondaryFeatureChannelIndices, gridIndex);
}

kernel void gatherArrayAndSingleToSingle(
    texture2d_array<half, access::read> inputImageA [[texture(0)]],
    texture2d<half, access::read> inputImageB [[texture(1)]],
    texture2d<half, access::write> outputImage [[texture(2)]],
    constant ushort *primaryFeatureChannelIndices [[buffer(0)]],
    constant ushort *secondaryFeatureChannelIndices [[buffer(1)]],
    uint2 gridIndex [[thread_position_in_grid]]) {
  binaryGather(inputImageA, inputImageB, outputImage, primaryFeatureChannelIndices,
               secondaryFeatureChannelIndices, gridIndex);
}

kernel void gatherArrayAndSingleToArray(
    texture2d_array<half, access::read> inputImageA [[texture(0)]],
    texture2d<half, access::read> inputImageB [[texture(1)]],
    texture2d_array<half, access::write> outputImage [[texture(2)]],
    constant ushort *primaryFeatureChannelIndices [[buffer(0)]],
    constant ushort *secondaryFeatureChannelIndices [[buffer(1)]],
    uint2 gridIndex [[thread_position_in_grid]]) {
  binaryGather(inputImageA, inputImageB, outputImage, primaryFeatureChannelIndices,
               secondaryFeatureChannelIndices, gridIndex);
}

kernel void gatherArrayAndArrayToSingle(
    texture2d_array<half, access::read> inputImageA [[texture(0)]],
    texture2d_array<half, access::read> inputImageB [[texture(1)]],
    texture2d<half, access::write> outputImage [[texture(2)]],
    constant ushort *primaryFeatureChannelIndices [[buffer(0)]],
    constant ushort *secondaryFeatureChannelIndices [[buffer(1)]],
    uint2 gridIndex [[thread_position_in_grid]]) {
  binaryGather(inputImageA, inputImageB, outputImage, primaryFeatureChannelIndices,
               secondaryFeatureChannelIndices, gridIndex);
}

kernel void gatherArrayAndArrayToArray(
    texture2d_array<half, access::read> inputImageA [[texture(0)]],
    texture2d_array<half, access::read> inputImageB [[texture(1)]],
    texture2d_array<half, access::write> outputImage [[texture(2)]],
    constant ushort *primaryFeatureChannelIndices [[buffer(0)]],
    constant ushort *secondaryFeatureChannelIndices [[buffer(1)]],
    uint2 gridIndex [[thread_position_in_grid]]) {
  binaryGather(inputImageA, inputImageB, outputImage, primaryFeatureChannelIndices,
               secondaryFeatureChannelIndices, gridIndex);
}
