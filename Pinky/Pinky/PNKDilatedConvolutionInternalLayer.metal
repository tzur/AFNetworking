// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#include <metal_stdlib>

#include "PNKActivation.metal.h"
#include "PNKTemplatedIO.metal"

using namespace metal;

constant uint2 dilationRate[[function_constant(0)]];
constant uint2 kernelGap[[function_constant(1)]];
constant uint2 stride[[function_constant(2)]];
constant const ushort activationType [[function_constant(3)]];
constant const bool hasAlphaBuffer [[function_constant(4)]];
constant const bool hasBetaBuffer [[function_constant(5)]];

/// This kernel copies pixels from a monolitic input texture to a patch-based output texture. The
/// number of patches (in each direction) equals \c dilationRate. The working space size is that of
/// the patch with the kernel gap. An internal (nested) loop iterates through all patches. The
/// loop body calculates the positions of the pixel in the input and output textures and then copies
/// the pixel.
template <typename U, typename V>
void space2Patch(constant uint2 *fullPaddingTF [[buffer(0)]], U inputTexture [[texture(0)]],
                 V outputTexture [[texture(1)]], uint3 gid [[thread_position_in_grid]]) {
  const uint2 inputTextureSize(inputTexture.get_width(), inputTexture.get_height());
  const uint2 outputTextureSize(outputTexture.get_width(), outputTexture.get_height());
  const uint2 positionInPatch = gid.xy;
  const uint2 leftTopShift = fullPaddingTF[0] / 2;

  const uint2 patchSizeWithGap = (outputTextureSize + kernelGap) / dilationRate;

  if (any(positionInPatch >= patchSizeWithGap)) {
    return;
  }

  const bool inPatch = all(positionInPatch < patchSizeWithGap - kernelGap);

  for (uint patchX = 0; patchX < dilationRate.x; ++patchX) {
    for (uint patchY = 0; patchY < dilationRate.y; ++patchY) {
      const uint2 patchIndex = uint2(patchX, patchY);
      const uint2 writePosition = positionInPatch + patchIndex * patchSizeWithGap;
      if (any(writePosition >= outputTextureSize)) {
        continue;
      }
      const uint2 readPositionWithShift = patchIndex + positionInPatch * dilationRate;
      const bool readPositionIsValid = inPatch && all(readPositionWithShift >= leftTopShift) &&
          all(readPositionWithShift < inputTextureSize + leftTopShift);
      const uint2 readPosition = readPositionWithShift - leftTopShift;
      const half4 pixel =
          readPositionIsValid ? static_cast<half4>(lt::read(inputTexture, readPosition, gid.z)) : 0;
      lt::write(outputTexture, pixel, writePosition, gid.z);
    }
  }
}

kernel void space2PatchArray(constant uint2 *fullPaddingTF [[buffer(0)]],
                             texture2d_array<half, access::read> inputTexture [[texture(0)]],
                             texture2d_array<half, access::write> outputTexture [[texture(1)]],
                             uint3 gid [[thread_position_in_grid]]) {
  space2Patch(fullPaddingTF, inputTexture, outputTexture, gid);
}

kernel void space2PatchSingle(constant uint2 *fullPaddingTF [[buffer(0)]],
                              texture2d<half, access::read> inputTexture [[texture(0)]],
                              texture2d<half, access::write> outputTexture [[texture(1)]],
                              uint3 gid [[thread_position_in_grid]]) {
  space2Patch(fullPaddingTF, inputTexture, outputTexture, gid);
}

/// This kernel copies pixels from a patch-based input texture to a monolitic output texture. The
/// number of patches (in each direction) equals \c dilationRate. The working space size is that of
/// the patch with the kernel gap patch (without padding). An internal (nested) loop iterates
/// through all patches. The loop body calculates the positions of the pixel in the input and output
/// textures, reads it from the input, activates it and writes to the output.
template <typename U, typename V>
void patch2Space(constant half4 *alpha, constant half4 *beta, U inputTexture, V outputTexture,
                 uint3 gid) {
  const uint2 inputTextureSize(inputTexture.get_width(), inputTexture.get_height());
  const uint2 outputTextureSize(outputTexture.get_width(), outputTexture.get_height());
  const uint2 positionInPatch = gid.xy;

  const uint2 patchSizeWithGap = (inputTextureSize + kernelGap) / dilationRate;
  const uint2 patchSize = patchSizeWithGap - kernelGap;
  if (any(positionInPatch >= patchSize)) {
    return;
  }

  for (uint patchX = 0; patchX < dilationRate.x; ++patchX) {
    for (uint patchY = 0; patchY < dilationRate.y; ++patchY) {
      const uint2 patchIndex = uint2(patchX, patchY);
      const uint2 writePositionWhenNoStride =
          patchIndex + positionInPatch * dilationRate;
      if (any(writePositionWhenNoStride % stride != 0)) {
        continue;
      }
      const uint2 writePosition = writePositionWhenNoStride / stride;
      if (any(writePosition >= outputTextureSize)) {
        continue;
      }

      const uint2 readPosition = positionInPatch + patchIndex * patchSizeWithGap;
      const half4 value = static_cast<half4>(lt::read(inputTexture, readPosition, gid.z));
      const half4 activatedValue = pnk::ActivatedValue(value, activationType, alpha, beta,
                                                       gid.z);
      lt::write(outputTexture, activatedValue, writePosition, gid.z);
    }
  }
}

kernel void patch2SpaceArray(constant half4 *alpha [[buffer(0), function_constant(hasAlphaBuffer)]],
                             constant half4 *beta [[buffer(1), function_constant(hasBetaBuffer)]],
                             texture2d_array<half, access::read> inputTexture [[texture(0)]],
                             texture2d_array<half, access::write> outputTexture [[texture(1)]],
                             uint3 gid [[thread_position_in_grid]]) {
  patch2Space(alpha, beta, inputTexture, outputTexture, gid);
}

kernel void patch2SpaceSingle(constant half4 *alpha [[buffer(0),
                                                      function_constant(hasAlphaBuffer)]],
                              constant half4 *beta [[buffer(1),
                                                     function_constant(hasBetaBuffer)]],
                              texture2d<half, access::read> inputTexture [[texture(0)]],
                              texture2d<half, access::write> outputTexture [[texture(1)]],
                              uint3 gid [[thread_position_in_grid]]) {
  patch2Space(alpha, beta, inputTexture, outputTexture, gid);
}
