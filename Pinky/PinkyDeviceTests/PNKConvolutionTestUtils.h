// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKNeuralNetworkOperationsModel.h"

NS_ASSUME_NONNULL_BEGIN

namespace pnk {
  struct ConvolutionKernelModel;
}

/// Creates a convolution kernel with given parameters and fills it with float weights in
/// the <tt>[-2, 2]</tt> interval in pseudo-random order.
cv::Mat1f PNKFillKernel(int kernelWidth, int kernelHeight, int inputChannels,
                        int outputChannels);

/// Calculates a convolution of half-float \c inputMatrix with float \c kernel using provided
/// \c dilation and \c stride. Zero-pading as per TF convention.
cv::Mat PNKCalculateConvolution(pnk::PaddingType padding, const cv::Mat &inputMatrix,
                                const cv::Mat1f &kernel, int dilationX, int dilationY, int strideX,
                                int strideY);

/// Builds a \c pnk::ConvolutionKernelModel with given parameters and no bias term.
pnk::ConvolutionKernelModel PNKBuildConvolutionModel(NSUInteger kernelWidth,
                                                     NSUInteger kernelHeight,
                                                     NSUInteger inputChannels,
                                                     NSUInteger outputChannels,
                                                     NSUInteger dilationX,
                                                     NSUInteger dilationY,
                                                     NSUInteger strideX,
                                                     NSUInteger strideY,
                                                     pnk::PaddingType paddingType);

NS_ASSUME_NONNULL_END
