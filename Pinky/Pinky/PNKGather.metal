/// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#include <metal_stdlib>

#include "PNKTemplatedIO.metal"

using namespace metal;

constant ushort outputFeatureChannels [[function_constant(0)]];
constant ushort4 outputFeatureChannelsShortList [[function_constant(1)]];

template <typename T>
void gatherToSingle(T inputImage [[texture(0)]],
                    texture2d<half, access::write> outputImage [[texture(1)]],
                    uint2 gridIndex [[thread_position_in_grid]]) {
  if (gridIndex.x >= outputImage.get_width() || gridIndex.y >= outputImage.get_height()) {
    return;
  }

  half4 pixel(0.0);

  ushort sampledChunks[4];
  half4 sampledChunkValues[4];

  for (ushort outputChannel = 0; outputChannel < outputFeatureChannels; ++outputChannel) {
    ushort inputChannel = outputFeatureChannelsShortList[outputChannel];
    ushort inputChunk = inputChannel / 4;
    bool alreadySampled = false;
    half4 inputChunkValue;
    for (int i = 0; i < outputChannel; ++i) {
      if (sampledChunks[i] == inputChunk) {
        alreadySampled = true;
        inputChunkValue = sampledChunkValues[i];
        break;
      }
    }

    if (!alreadySampled) {
      inputChunkValue = lt::read(inputImage, gridIndex, inputChunk);
    }

    sampledChunks[outputChannel] = inputChunk;
    sampledChunkValues[outputChannel] = inputChunkValue;

    pixel[outputChannel] = inputChunkValue[inputChannel % 4];
  }

  outputImage.write(pixel, gridIndex, 0);
}

kernel void gatherSingleToSingle(texture2d<half, access::read> inputImage [[texture(0)]],
                                 texture2d<half, access::write> outputImage [[texture(1)]],
                                 uint2 gridIndex [[thread_position_in_grid]]) {
  gatherToSingle(inputImage, outputImage, gridIndex);
}

kernel void gatherArrayToSingle(texture2d_array<half, access::read> inputImage [[texture(0)]],
                                texture2d<half, access::write> outputImage [[texture(1)]],
                                uint2 gridIndex [[thread_position_in_grid]]) {
  gatherToSingle(inputImage, outputImage, gridIndex);
}

template <typename T>
void gatherToArray(T inputImage [[texture(0)]],
                   texture2d_array<half, access::write> outputImage [[texture(1)]],
                   constant ushort *outputFeatureChannelsLongList [[buffer(0)]],
                   uint2 gridIndex [[thread_position_in_grid]]) {
  if (gridIndex.x >= outputImage.get_width() || gridIndex.y >= outputImage.get_height()) {
    return;
  }

  half4 pixel(0.0);

  bool sampledChunkPresents = false;
  ushort lastSampledChunk;
  half4 lastSampledValue(0.0);

  for (ushort outputChannel = 0; outputChannel < outputFeatureChannels; ++outputChannel) {
    ushort inputChannel = outputFeatureChannelsLongList[outputChannel];
    ushort inputChunk = inputChannel / 4;

    half4 inputChunkValue = (sampledChunkPresents && (inputChunk == lastSampledChunk)) ?
        lastSampledValue : lt::read(inputImage, gridIndex, inputChunk);

    sampledChunkPresents = true;
    lastSampledChunk = inputChunk;
    lastSampledValue = inputChunkValue;

    pixel[outputChannel % 4] = inputChunkValue[inputChannel % 4];
    if ((outputChannel % 4 == 3) || (outputChannel == outputFeatureChannels - 1)) {
      outputImage.write(pixel, gridIndex, outputChannel / 4, 0);
      pixel = 0.0;
    }
  }
}

kernel void gatherSingleToArray(texture2d<half, access::read> inputImage [[texture(0)]],
                                texture2d_array<half, access::write> outputImage [[texture(1)]],
                                constant ushort *outputFeatureChannelsLongList [[buffer(0)]],
                                uint2 gridIndex [[thread_position_in_grid]]) {
  gatherToArray(inputImage, outputImage, outputFeatureChannelsLongList, gridIndex);
}

kernel void gatherArrayToArray(texture2d_array<half, access::read> inputImage [[texture(0)]],
                               texture2d_array<half, access::write> outputImage [[texture(1)]],
                               constant ushort *outputFeatureChannelsLongList [[buffer(0)]],
                               uint2 gridIndex [[thread_position_in_grid]]) {
  gatherToArray(inputImage, outputImage, outputFeatureChannelsLongList, gridIndex);
}
