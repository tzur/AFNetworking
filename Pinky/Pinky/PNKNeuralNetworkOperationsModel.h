// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKNeuralNetworkTypeDefinitions.h"

NS_ASSUME_NONNULL_BEGIN

namespace pnk {

#pragma mark -
#pragma mark Preprocessing
#pragma mark -

/// Parameters defining a per pixel scaling and bias operation to a 3 or 1 channel image. Each pixel
/// is first multiplied with the scaling factor and then the corresponding bias for each channel is
/// added.
struct ImageScaleBiasModel {
  /// Scalar to be multiplied by all channels prior to adding the biases.
  float channelScale;
  /// Scalar bias to be added to the blue channel.
  float blueBias;
  /// Scalar bias to be added to the green channel.
  float greenBias;
  /// Scalar bias to be added to the red channel.
  float redBias;
  /// Scalar bias to be added for grayscale images.
  float grayBias;
};

#pragma mark -
#pragma mark Neural Network basic operations
#pragma mark -

/// Parameters defining the behaviour of a convolutional layer in a neural network.
struct ConvolutionKernelModel {
  /// Width of the filter window.
  NSUInteger kernelWidth;
  /// Height of the filter window.
  NSUInteger kernelHeight;
  /// Number of feature channels in the filter window. Must be equal to <tt>inputFeatureChannels /
  /// groups</tt>.
  NSUInteger kernelChannels;
  /// Number of groups input and output channels are divided into. The default value is 1, such that
  /// all input channels are connected to all output channels. If groups is set to n, input is
  /// divided into n groups with <tt>inputFeatureChannels / n</tt> channels in each group. Similarly
  /// output is divided into n groups with <tt>outputFeatureChannels / n</tt> channels in each
  /// group. Each input group is connected only to its corresponding output group. Both
  /// \c inputFeatureChannels and \c outputFeatureChannels must be divisible by \c groups and number
  /// of channels in each group must be a multiple of 4.
  ///
  /// @note Groups lets you reduce the amount of parameters and computations used in the kernel.
  /// Given the connectivity pattern, the number of parameters is reduced by a factor of \c groups
  /// compared to the default value of 1.
  NSUInteger groups;
  /// Number of feature channels per pixel in the input image.
  NSUInteger inputFeatureChannels;
  /// Number of feature channels per pixel in the output image.
  NSUInteger outputFeatureChannels;
  /// Output stride (downsampling factor) in the x dimension. The default value is 1.
  NSUInteger strideX;
  /// Output stride (downsampling factor) in the y dimension. The default value is 1.
  NSUInteger strideY;
  /// Kernel dilation in the x dimension. The default value is 1.
  NSUInteger dilationX;
  /// Kernel dilation in the y dimension. The default value is 1.
  NSUInteger dilationY;
  /// Padding type controling the size of the output.
  PaddingType padding;
  /// \c YES iff the kernel performs deconvolution. The default value is \c NO.
  BOOL isDeconvolution;
  /// \c YES iff the kernel applies a bias after convolution. The default value is \c NO.
  BOOL hasBias;
  /// Output shape used in case \c isDeconvolution is \c YES. If not set the output size for a
  /// deconvolution will be calculated by the input size and \c padding.
  CGSize deconvolutionOutputSize;
  /// Matrix of weights for the convolution kernel. If \c isDeconvolution is \c NO, the shape of the
  /// matrix is <tt>[outputFeatureChannels, kernelHeight, kernelWidth, inputFeatureChannels]</tt>.
  /// If \c isDeconvolution is \c YES, the shape of the matrix is
  /// <tt>[inputFeatureChannels, outputFeatureChannels, kernelHeight, kernelWidth]</tt>. The matrix
  /// must have a single channel of either float or half-float depth.
  cv::Mat kernelWeights;
  /// Matrix of weights for the bias added after convolution. Must be of size
  /// \c outputFeatureChannels.
  cv::Mat1f biasWeights;
};

/// Parameters defining the behaviour of a pooling layer in a neural network.
struct PoolingKernelModel {
  /// Pooling function to apply in each kernel window.
  PoolingType pooling;
  /// Width of the filter window.
  NSUInteger kernelWidth;
  /// Height of the filter window.
  NSUInteger kernelHeight;
  /// Output stride (downsampling factor) in the x dimension. The default value is 1.
  NSUInteger strideX;
  /// Output stride (downsampling factor) in the y dimension. The default value is 1.
  NSUInteger strideY;
  /// Padding type controling the size of the output.
  PaddingType padding;
  /// If \c YES then the pooling operation will exclude padding pixels from the calculation of the
  /// average.
  BOOL averagePoolExcludePadding;
  /// If \c YES then pooling is performed on the entire input and kernel size is disregarded.
  BOOL globalPooling;
};

/// Parameters defining the behaviour of an activation layer in a neural network.
struct ActivationKernelModel {
  /// Activation function.
  ActivationType activationType;
  /// Matrix of the first parameter (alpha). In cases where the parametric activation is degenerate
  /// (i.e. same parameter is used across all channels) this matrix will be of size 1x1, otherwise
  /// it will be of size 1xC such that C is the expected \c inputFeatureChannels. For activation
  /// functions that do not use this parameter, its content is undefined.
  cv::Mat1f alpha;
  /// Matrix of the second parameter (beta). In cases where the parametric activation is degenerate
  /// (i.e. same parameter is used across all channels) this matrix will be of size 1x1, otherwise
  /// it will be of size 1xC such that C is the expected \c inputFeatureChannels. For activation
  /// functions that do not use this parameter, its content is undefined.
  cv::Mat1f beta;
};

#pragma mark -
#pragma mark Nerual Network normalization operations
#pragma mark -

/// Parameters defining the behaviour of a normalization layer in a neural network.
struct NormalizationKernelModel {
  /// Number of feature channels per pixel in the input image.
  NSUInteger inputFeatureChannels;
  /// If \c YES then \c mean and \c variance are ignored and calculated ad hoc.
  BOOL computeMeanVar;
  /// If \c YES then the mean and variance of each channel of the input is calculated per image and
  /// not for the entire batch. If \c computeMeanVar is \c NO, this value is ignored and precomputed
  /// values are used.
  BOOL instanceNormalization;
  /// A small constant to avoid division by 0 while normalizing by \c variance. Default is \c 1e-5.
  float epsilon;
  /// Matrix of weights for the scaling applied after normalization. Must be of size
  /// \c inputFeatureChannels.
  cv::Mat1f scale;
  /// Matrix of weights for the bias added after normalization. Must be of size
  /// \c inputFeatureChannels.
  cv::Mat1f shift;
  /// Matrix of precalculated mean values per channel for normalization. Must be of size
  /// \c inputFeatureChannels.
  cv::Mat1f mean;
  /// Matrix of precalculated variance values per channel for normalization. Must be of size
  /// \c inputFeatureChannels.
  cv::Mat1f variance;
};

} // namespace pnk

NS_ASSUME_NONNULL_END
