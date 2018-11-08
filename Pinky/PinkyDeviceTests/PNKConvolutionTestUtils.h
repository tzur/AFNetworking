// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKNeuralNetworkOperationsModel.h"

NS_ASSUME_NONNULL_BEGIN

namespace pnk {
  struct ConvolutionKernelModel;
}

/// Calculates a convolution of half-float \c inputMatrix with float \c kernel using provided
/// \c dilation and \c stride. Zero-pading as per TF convention.
cv::Mat PNKCalculateConvolution(pnk::PaddingType padding, const cv::Mat &inputMatrix,
                                const cv::Mat &kernel, int dilationX, int dilationY, int strideX,
                                int strideY, pnk::ActivationType activationType,
                                const cv::Mat &alpha, const cv::Mat &beta);

/// Calculates an activation of half-float \c inputMatrix with the given activated parameters.
cv::Mat PNKCalculateActivation(const cv::Mat &inputMatrix, pnk::ActivationType activationType,
                               const cv::Mat &alpha, const cv::Mat &beta);

/// Builds a \c pnk::ConvolutionKernelModel with given parameters.
pnk::ConvolutionKernelModel PNKBuildConvolutionModel(NSUInteger kernelWidth,
                                                     NSUInteger kernelHeight,
                                                     NSUInteger inputChannels,
                                                     NSUInteger outputChannels,
                                                     NSUInteger groups,
                                                     NSUInteger dilationX,
                                                     NSUInteger dilationY,
                                                     NSUInteger strideX,
                                                     NSUInteger strideY,
                                                     pnk::PaddingType paddingType);

/// Builds a \c pnk::ActivationKernelModel with given \c featureChannels and \c activationType.
/// Fills \c alpha and \c beta parameters with random float numbers.
pnk::ActivationKernelModel PNKBuildActivationModel(NSUInteger featureChannels,
                                                   pnk::ActivationType activationType);

/// Calculates activation of \c value with the given \c activationType and \c alpha and \c beta
/// parameters.
half_float::half PNKActivatedValue(half_float::half value, int channel,
                                   pnk::ActivationType activationType, const cv::Mat1f &alpha,
                                   const cv::Mat1f &beta);

/// Calculates a unary function on half-float \c inputMatrix with the given parameters.
cv::Mat PNKCalculateUnary(const cv::Mat &inputMatrix, pnk::UnaryType unaryType, float alpha,
                          float scale, float shift, float epsilon);

/// Calculates a unary function of \c value with the given \c unaryType, \c alpha parameter,
/// \c scale and \c shift.
half_float::half PNKUnaryFunction(half_float::half value, pnk::UnaryType unaryType, float alpha,
                                  float scale, float shift, float epsilon);

NS_ASSUME_NONNULL_END
