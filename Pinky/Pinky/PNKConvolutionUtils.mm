// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKConvolutionUtils.h"

NS_ASSUME_NONNULL_BEGIN

static NSUInteger PNKDilatedKernelSize(NSUInteger kernelSize, NSUInteger dilation) {
  return (kernelSize - 1) * dilation + 1;
}

static NSUInteger PNKOneDimensionFullPaddingTF(NSUInteger imageSize, NSUInteger kernelSize,
                                               NSUInteger dilation, NSUInteger stride,
                                               pnk::PaddingType padding) {
  NSUInteger dilatedKernelSize = PNKDilatedKernelSize(kernelSize, dilation);
  switch (padding) {
    case pnk::PaddingTypeSame: {
      NSUInteger strideResidual = (imageSize - 1) % stride + 1;
      return std::max(static_cast<NSInteger>(dilatedKernelSize - strideResidual), (NSInteger)0);
    }
    case pnk::PaddingTypeValid:
      return 0;
  }
}

pnk::PaddingSize PNKConvolutionFullPaddingTF(NSUInteger imageWidth, NSUInteger imageHeight,
                                             NSUInteger kernelWidth, NSUInteger kernelHeight,
                                             NSUInteger dilationX, NSUInteger dilationY,
                                             NSUInteger strideX, NSUInteger strideY,
                                             pnk::PaddingType padding) {
  return {
    .x = PNKOneDimensionFullPaddingTF(imageWidth, kernelWidth, dilationX, strideX, padding),
    .y = PNKOneDimensionFullPaddingTF(imageHeight, kernelHeight, dilationY, strideY, padding),
  };
}

pnk::PaddingSize PNKConvolutionLeftTopPaddingMPS(NSUInteger kernelWidth, NSUInteger kernelHeight,
                                                 NSUInteger dilationX, NSUInteger dilationY) {
  return  {
    .x = PNKDilatedKernelSize(kernelWidth, dilationX) / 2,
    .y = PNKDilatedKernelSize(kernelHeight, dilationY) / 2,
  };
}

MPSOffset PNKConvolutionOffset(NSUInteger imageWidth, NSUInteger imageHeight, NSUInteger
                               kernelWidth, NSUInteger kernelHeight, NSUInteger dilationX,
                               NSUInteger dilationY, NSUInteger strideX, NSUInteger strideY,
                               pnk::PaddingType paddingType) {
  pnk::PaddingSize topLeftPaddingMPS = PNKConvolutionLeftTopPaddingMPS(kernelWidth, kernelHeight,
                                                                       dilationX, dilationY);
  pnk::PaddingSize fullPaddingTF = PNKConvolutionFullPaddingTF(imageWidth, imageHeight, kernelWidth,
                                                               kernelHeight, dilationX, dilationY,
                                                               strideX, strideY, paddingType);
  return {
    .x = static_cast<NSInteger>(topLeftPaddingMPS.x - fullPaddingTF.x / 2),
    .y = static_cast<NSInteger>(topLeftPaddingMPS.y - fullPaddingTF.y / 2),
    .z = 0
  };
}

MTLSize PNKConvolutionOutputSize(MTLSize inputSize, NSUInteger kernelWidth, NSUInteger kernelHeight,
                                 NSUInteger dilationX, NSUInteger dilationY, NSUInteger strideX,
                                 NSUInteger strideY, pnk::PaddingType padding,
                                 NSUInteger outputDepth) {
  switch (padding) {
    case pnk::PaddingTypeSame:
      return {
        (inputSize.width - 1) / strideX + 1,
        (inputSize.height - 1) / strideY + 1,
        outputDepth
      };
    case pnk::PaddingTypeValid:
      return {
        (inputSize.width - PNKDilatedKernelSize(kernelWidth, dilationX)) / strideX + 1,
        (inputSize.height - PNKDilatedKernelSize(kernelHeight, dilationY)) / strideY + 1,
        outputDepth
      };
  }
}

MTLSize PNKConvolutionInputSize(MTLSize outputSize, NSUInteger kernelWidth, NSUInteger kernelHeight,
                                NSUInteger dilationX, NSUInteger dilationY, NSUInteger strideX,
                                NSUInteger strideY, pnk::PaddingType padding,
                                NSUInteger inputDepth) {
  switch (padding) {
    case pnk::PaddingTypeSame:
      return {
        (outputSize.width - 1) * strideX + 1,
        (outputSize.height - 1) * strideY + 1,
        inputDepth
      };
    case pnk::PaddingTypeValid:
      return {
        (outputSize.width - 1) * strideX + PNKDilatedKernelSize(kernelWidth, dilationX),
        (outputSize.height - 1) * strideY + PNKDilatedKernelSize(kernelHeight, dilationY),
        outputSize.depth
      };
  }
}

NS_ASSUME_NONNULL_END
