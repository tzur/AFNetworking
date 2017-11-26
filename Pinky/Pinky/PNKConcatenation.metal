// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#include <metal_stdlib>

#include "PNKTemplatedIO.metal"

using namespace metal;

constant ushort primaryInputFeatureChannels [[function_constant(0)]];
constant ushort secondaryInputFeatureChannels [[function_constant(1)]];

constant ushort primaryBodyChunksCount = primaryInputFeatureChannels / 4;
constant ushort primaryTailSize = primaryInputFeatureChannels - primaryBodyChunksCount * 4;
constant ushort secondaryHeadSize = (secondaryInputFeatureChannels < 4 - primaryTailSize) ?
    secondaryInputFeatureChannels : (4 - primaryTailSize);
constant ushort secondaryBodyChunksCount =
    (secondaryInputFeatureChannels - secondaryHeadSize + 3) / 4;

template <typename U, typename V, typename W>
void concat(U inputImageA [[texture(0)]],
            V inputImageB [[texture(1)]],
            W outputImage [[texture(2)]],
            ushort2 gridIndex [[thread_position_in_grid]]) {
  if (gridIndex.x >= inputImageA.get_width() || gridIndex.y >= inputImageA.get_height()) {
    return;
  }

  // Copy the body of Primary.
  for (ushort chunk = 0; chunk < primaryBodyChunksCount; ++chunk) {
    half4 a = lt::read(inputImageA, gridIndex, chunk);
    lt::write(outputImage, a, gridIndex, chunk);
  }

  // Copy the tail of Primary + the head of Secondary.
  half4 result = 0;

  if (primaryTailSize) {
    result = static_cast<half4>(lt::read(inputImageA, gridIndex, primaryBodyChunksCount));
  }

  half4 b = static_cast<half4>(lt::read(inputImageB, gridIndex, 0));

  for (ushort channel = 0; channel < secondaryHeadSize; ++channel) {
    result[primaryTailSize + channel] = b[channel];
  }

  lt::write(outputImage, result, gridIndex, primaryBodyChunksCount);

  // Copy the body and the tail of Secondary.
  half4 previousB = b;
  for (ushort chunk = 1; chunk <= secondaryBodyChunksCount; ++chunk) {
    half4 nextB = lt::read(inputImageB, gridIndex, chunk);

    half4 result = 0;
    switch (primaryTailSize) {
      case 0:
        result = nextB;
        break;
      case 1:
        result = half4(previousB.a, nextB.rgb);
        break;
      case 2:
        result = half4(previousB.ba, nextB.rg);
        break;
      case 3:
        result = half4(previousB.gba, nextB.r);
        break;
    }

    lt::write(outputImage, result, gridIndex, primaryBodyChunksCount + chunk);
    previousB = nextB;
  }
}

kernel void concatSingleAndSingleToSingle(texture2d<half, access::read> inputImageA [[texture(0)]],
                                          texture2d<half, access::read> inputImageB [[texture(1)]],
                                          texture2d<half, access::write> outputImage [[texture(2)]],
                                          ushort2 gridIndex [[thread_position_in_grid]]) {
  concat(inputImageA, inputImageB, outputImage, gridIndex);
}

kernel void concatSingleAndSingleToArray(texture2d<half, access::read> inputImageA [[texture(0)]],
                                         texture2d<half, access::read> inputImageB [[texture(1)]],
                                         texture2d_array<half, access::write> outputImage [[texture(2)]],
                                         ushort2 gridIndex [[thread_position_in_grid]]) {
  concat(inputImageA, inputImageB, outputImage, gridIndex);
}

kernel void concatSingleAndArrayToArray(texture2d<half, access::read> inputImageA [[texture(0)]],
                                        texture2d_array<half, access::read> inputImageB [[texture(1)]],
                                        texture2d_array<half, access::write> outputImage [[texture(2)]],
                                        ushort2 gridIndex [[thread_position_in_grid]]) {
  concat(inputImageA, inputImageB, outputImage, gridIndex);
}

kernel void concatArrayAndSingleToArray(texture2d_array<half, access::read> inputImageA [[texture(0)]],
                                        texture2d<half, access::read> inputImageB [[texture(1)]],
                                        texture2d_array<half, access::write> outputImage [[texture(2)]],
                                        ushort2 gridIndex [[thread_position_in_grid]]) {
  concat(inputImageA, inputImageB, outputImage, gridIndex);
}

kernel void concatArrayAndArrayToArray(texture2d_array<half, access::read> inputImageA [[texture(0)]],
                                       texture2d_array<half, access::read> inputImageB [[texture(1)]],
                                       texture2d_array<half, access::write> outputImage [[texture(2)]],
                                       ushort2 gridIndex [[thread_position_in_grid]]) {
  concat(inputImageA, inputImageB, outputImage, gridIndex);
}
