// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKNeuralNetworkOperationsModel.h"

NS_ASSUME_NONNULL_BEGIN

namespace pnk {
  /// Padding size in pixels.
  struct PaddingSize {
    /// Padding in X-direction (left, right or sum thereof).
    NSUInteger x;
    /// Padding in Y-direction (top, bottom or sum thereof).
    NSUInteger y;
  };
}

/// Calculates full padding <tt>(left + right, top + bottom)</tt> for given input image size and
/// convolution parameters in TF convention.  For more details see
/// https://www.tensorflow.org/api_guides/python/nn#Convolution.
pnk::PaddingSize PNKConvolutionFullPaddingTF(NSUInteger imageWidth, NSUInteger imageHeight,
                                             NSUInteger kernelWidth, NSUInteger kernelHeight,
                                             NSUInteger dilationX, NSUInteger dilationY,
                                             NSUInteger strideX, NSUInteger strideY,
                                             pnk::PaddingType paddingType) API_AVAILABLE(ios(10.0));

/// Calculates <tt>(left, top)</tt> padding for given convolution parameters in MPS convention.
pnk::PaddingSize PNKConvolutionLeftTopPaddingMPS(NSUInteger kernelWidth, NSUInteger kernelHeight,
                                                 NSUInteger dilationX, NSUInteger dilationY)
    API_AVAILABLE(ios(10.0));

/// Calculates the difference between <tt>(left, top)</tt> paddings for given input image size and
/// convolution parameters in TF and MPS conventions.
MPSOffset PNKConvolutionOffset(NSUInteger imageWidth, NSUInteger imageHeight, NSUInteger
                               kernelWidth, NSUInteger kernelHeight, NSUInteger dilationX,
                               NSUInteger dilationY, NSUInteger strideX, NSUInteger strideY,
                               pnk::PaddingType paddingType) API_AVAILABLE(ios(10.0));

/// Calculates the output image size for given input image size and convolution parameters.
MTLSize PNKConvolutionOutputSize(MTLSize inputSize, NSUInteger kernelWidth, NSUInteger kernelHeight,
                                 NSUInteger dilationX, NSUInteger dilationY, NSUInteger strideX,
                                 NSUInteger strideY, pnk::PaddingType padding,
                                 NSUInteger outputDepth) API_AVAILABLE(ios(10.0));

/// Calculates the input image size for given output image size and convolution parameters.
MTLSize PNKConvolutionInputSize(MTLSize outputSize, NSUInteger kernelWidth, NSUInteger kernelHeight,
                                NSUInteger dilationX, NSUInteger dilationY, NSUInteger strideX,
                                NSUInteger strideY, pnk::PaddingType paddingType,
                                NSUInteger inputDepth) API_AVAILABLE(ios(10.0));

NS_ASSUME_NONNULL_END
