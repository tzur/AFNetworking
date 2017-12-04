// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#include <metal_stdlib>

#include "PNKTemplatedIO.metal"

using namespace metal;

constant ushort2 dilationRate[[function_constant(0)]];
constant ushort2 kernelGap[[function_constant(1)]];
constant ushort2 paddingSize[[function_constant(2)]];

/// This kernel copies pixels from a monolitic input texture to a patch-based output texture. The
/// number of patches (in each direction) equals \c dilationRate. The working space size is that of
/// the patch with the kernel gap. An internal (nested) loop iterates through all patches. The
/// loop body calculates the positions of the pixel in the input and output textures and then copies
/// the pixel.
template <typename U, typename V>
void space2Patch(U inputTexture [[texture(0)]], V outputTexture [[texture(1)]],
                 ushort3 gid [[thread_position_in_grid]]) {
  const ushort2 inputTextureSize(inputTexture.get_width(), inputTexture.get_height());
  const ushort2 outputTextureSize(outputTexture.get_width(), outputTexture.get_height());
  const ushort2 positionInPatch = gid.xy;

  const ushort2 patchSizeWithGap = (outputTextureSize + kernelGap) / dilationRate;

  if (any(positionInPatch >= patchSizeWithGap)) {
    return;
  }

  const bool inPatch = all(positionInPatch < patchSizeWithGap - kernelGap);

  for (ushort patchX = 0; patchX < dilationRate.x; ++patchX) {
    for (ushort patchY = 0; patchY < dilationRate.y; ++patchY) {
      const ushort2 patchIndex = ushort2(patchX, patchY);
      const ushort2 writePosition = positionInPatch + patchIndex * patchSizeWithGap;
      if (any(writePosition >= outputTextureSize)) {
        continue;
      }
      const ushort2 readPosition = patchIndex + positionInPatch * dilationRate;
      const bool readPositionIsValid = inPatch && all(readPosition < inputTextureSize);
      const half4 pixel =
          readPositionIsValid ? static_cast<half4>(lt::read(inputTexture, readPosition, gid.z)) : 0;
      lt::write(outputTexture, pixel, writePosition, gid.z);
    }
  }
}

kernel void space2PatchArray(texture2d_array<half, access::read> inputTexture [[texture(0)]],
                             texture2d_array<half, access::write> outputTexture [[texture(1)]],
                             ushort3 gid [[thread_position_in_grid]]) {
  space2Patch(inputTexture, outputTexture, gid);
}

kernel void space2PatchSingle(texture2d<half, access::read> inputTexture [[texture(0)]],
                              texture2d<half, access::write> outputTexture [[texture(1)]],
                              ushort3 gid [[thread_position_in_grid]]) {
  space2Patch(inputTexture, outputTexture, gid);
}

/// This kernel copies pixels from a patch-based input texture to a monolitic output texture. The
/// number of patches (in each direction) equals \c dilationRate. The working space size is that of
/// the patch with the kernel gap patch (without padding). An internal (nested) loop iterates
/// through all patches. The loop body calculates the positions of the pixel in the input and output
/// textures and then copies the pixel.
template <typename U, typename V>
void patch2Space(U inputTexture [[texture(0)]], V outputTexture [[texture(1)]],
                 ushort3 gid [[thread_position_in_grid]]) {
  const ushort2 inputTextureSize(inputTexture.get_width(), inputTexture.get_height());
  const ushort2 outputTextureSize(outputTexture.get_width(), outputTexture.get_height());
  const ushort2 positionInPatchWithoutPadding = gid.xy;
  const ushort2 positionInPatch = positionInPatchWithoutPadding + paddingSize;

  const ushort2 patchSizeWithGap = (inputTextureSize + kernelGap) / dilationRate;
  const ushort2 patchSize = patchSizeWithGap - kernelGap;
  const ushort2 patchSizeWithoutPadding = patchSize - 2 * paddingSize;
  if (any(positionInPatchWithoutPadding >= patchSizeWithoutPadding)) {
    return;
  }

  for (ushort patchX = 0; patchX < dilationRate.x; ++patchX) {
    for (ushort patchY = 0; patchY < dilationRate.y; ++patchY) {
      const ushort2 patchIndex = ushort2(patchX, patchY);
      const ushort2 writePosition = patchIndex + positionInPatchWithoutPadding * dilationRate;
      if (any(writePosition >= outputTextureSize)) {
        continue;
      }
      const ushort2 readPosition = positionInPatch + patchIndex * patchSizeWithGap;
      const half4 pixel = static_cast<half4>(lt::read(inputTexture, readPosition, gid.z));
      lt::write(outputTexture, pixel, writePosition, gid.z);
    }
  }
}

kernel void patch2SpaceArray(texture2d_array<half, access::read> inputTexture [[texture(0)]],
                             texture2d_array<half, access::write> outputTexture [[texture(1)]],
                             ushort3 gid [[thread_position_in_grid]]) {
  patch2Space(inputTexture, outputTexture, gid);
}

kernel void patch2SpaceSingle(texture2d<half, access::read> inputTexture [[texture(0)]],
                              texture2d<half, access::write> outputTexture [[texture(1)]],
                              ushort3 gid [[thread_position_in_grid]]) {
  patch2Space(inputTexture, outputTexture, gid);
}
