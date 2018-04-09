// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "MPSCNNConvolution+Factory.h"

#import "MPSCNNNeuron+Factory.h"
#import "PNKCNNConvolutionDataSource.h"
#import "PNKNeuralNetworkOperationsModel.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface MPSCNNConvolution ()

/// Declaration of a deprecated initializer of \c MPSCNNConvolution class. It is the only
/// initializer available in iOS 10. Apple decided to drop it from the header file in iOS 11.3.
- (instancetype)initWithDevice:(id<MTLDevice>)device
         convolutionDescriptor:(const MPSCNNConvolutionDescriptor *)convolutionDescriptor
                 kernelWeights:(const float *)kernelWeights
                     biasTerms:(const float *)biasTerms flags:(MPSCNNConvolutionFlags)flags
    MPS_AVAILABLE_STARTING_BUT_DEPRECATED("Please use initWithDevice:weights: instead.",
                                          ios(10.0, 11.0));

@end

@implementation MPSCNNConvolution (Factory)

+ (MPSCNNConvolution *)pnk_cnnConvolutionWithDevice:(id<MTLDevice>)device
    convolutionModel:(const pnk::ConvolutionKernelModel &)convolutionModel
    activationModel:(const pnk::ActivationKernelModel &)activationModel {
  [self validateConvolutionModelGroups:convolutionModel];
  [self validateConvolutionModelWeights:convolutionModel];

  if (@available(iOS 11.0, *)) {
    auto dataSource = [[PNKCNNConvolutionDataSource alloc] initWithConvolutionModel:convolutionModel
                       activationModel:activationModel];
    return [[MPSCNNConvolution alloc] initWithDevice:device weights:dataSource];
  } else {
    cv::Mat kernelWeightsMat = convolutionModel.kernelWeights;
    auto neuronActivation = [MPSCNNNeuron pnk_cnnNeuronWithDevice:device
                                                  activationModel:activationModel];
    auto descriptor = [MPSCNNConvolutionDescriptor
                       cnnConvolutionDescriptorWithKernelWidth:convolutionModel.kernelWidth
                       kernelHeight:convolutionModel.kernelHeight
                       inputFeatureChannels:convolutionModel.inputFeatureChannels
                       outputFeatureChannels:convolutionModel.outputFeatureChannels
                       neuronFilter:neuronActivation];
    if (convolutionModel.groups > 1) {
      descriptor.groups = convolutionModel.groups / 4;
      kernelWeightsMat = [self blockDiagonalWeightsFromWeights:convolutionModel.kernelWeights
                                                      channels:convolutionModel.inputFeatureChannels
                                                   kernelWidth:convolutionModel.kernelWidth
                                                  kernelHeight:convolutionModel.kernelHeight];
    }

    descriptor.strideInPixelsX = convolutionModel.strideX;
    descriptor.strideInPixelsY = convolutionModel.strideY;

    float *kernelWeights = (float *)(kernelWeightsMat.data);
    float * _Nullable biasWeights = convolutionModel.hasBias ?
        (float *)(convolutionModel.biasWeights.data) : nil;

    return [[MPSCNNConvolution alloc] initWithDevice:device convolutionDescriptor:descriptor
                                       kernelWeights:kernelWeights biasTerms:biasWeights
                                               flags:MPSCNNConvolutionFlagsNone];

  }
}

+ (void)validateConvolutionModelGroups:(const pnk::ConvolutionKernelModel &)convolutionModel {
  if (convolutionModel.groups == 1) {
    return;
  }

  LTParameterAssert(convolutionModel.inputFeatureChannels ==
                    convolutionModel.outputFeatureChannels,
                    @"Convolution model with channel groups must have the same count of input "
                    "and output channels, got (%lu, %lu)",
                    (unsigned long)convolutionModel.inputFeatureChannels,
                    (unsigned long)convolutionModel.outputFeatureChannels);
  LTParameterAssert(convolutionModel.inputFeatureChannels == convolutionModel.groups,
                    @"Convolution model with channel groups must have the same count of input "
                    "channels and groups, got (%lu, %lu)",
                    (unsigned long)convolutionModel.inputFeatureChannels,
                    (unsigned long)convolutionModel.groups);
  LTParameterAssert(convolutionModel.inputFeatureChannels % 4 == 0,
                    @"Number of input channels must be divisible by 4, got: %lu",
                    (unsigned long)convolutionModel.inputFeatureChannels);
}

+ (void)validateConvolutionModelWeights:(const pnk::ConvolutionKernelModel &)convolutionModel {
  LTParameterAssert(convolutionModel.kernelWeights.total() ==
                    convolutionModel.outputFeatureChannels * convolutionModel.kernelHeight *
                    convolutionModel.kernelWidth * convolutionModel.inputFeatureChannels /
                    convolutionModel.groups, @"The kernel weights matrix must have "
                    "%lu * %lu * %lu * %lu / %lu = %lu members, got %lu",
                    (unsigned long)convolutionModel.outputFeatureChannels,
                    (unsigned long)convolutionModel.kernelHeight,
                    (unsigned long)convolutionModel.kernelWidth,
                    (unsigned long)convolutionModel.inputFeatureChannels,
                    (unsigned long)convolutionModel.groups,
                    (unsigned long)(convolutionModel.outputFeatureChannels *
                                    convolutionModel.kernelHeight *
                                    convolutionModel.kernelWidth *
                                    convolutionModel.inputFeatureChannels /
                                    convolutionModel.groups),
                    convolutionModel.kernelWeights.total());
  LTParameterAssert(convolutionModel.kernelWeights.isContinuous(), @"Kernel weights in model must "
                    "be continuous");
  LTParameterAssert(!convolutionModel.hasBias || convolutionModel.biasWeights.isContinuous(),
                    @"Bias weights in model must be continuous");
}

/// Builds the convolution weights array in the form ios 10's MPSCNNConvolution expects to obtain
/// them when <tt>groups > 1</tt>. In this case we have depthwise convolution with each output
/// channel being a result of convolution on its corresponding input channel only. The input
/// \c weights is a diagonal matrix from the input channels to output channels point of view. While
/// iOS 11 can process such a weights matrix as is, iOS 10 requires a block-diagonal matrix with a
/// block size of 4 x 4 channels. This function does the necessary transformation while filling
/// non-diagonal cells with zeroes.
///
/// Here is an illustration for a simple case of
/// <tt>channels == 8, kernelWidth == 1, kernelHeight == 1</tt>.
///
/// Input:                              Stored as:
/// ======                              ==========
/// a00                                 a00
///     a11                             a11
///         a22                         a22
///             a33                     a33
///                 a44                 a44
///                     a55             a55
///                         a66         a66
///                             a77     a77
///
/// Output:                             Stored as:
/// ======                              ==========
/// a00 0   0   0                       a00 0   0   0
/// 0   a11 0   0                       0   a11 0   0
/// 0   0   a22 0                       0   0   a22 0
/// 0   0   0   a33                     0   0   0   a33
///                 a44 0   0   0       a44 0   0   0
///                 0   a55 0   0       0   a55 0   0
///                 0   0   a66 0       0   0   a66 0
///                 0   0   0   a77     0   0   0   a77
///
+ (cv::Mat)blockDiagonalWeightsFromWeights:(const cv::Mat &)weights channels:(NSUInteger)channels
                               kernelWidth:(NSUInteger)kernelWidth
                              kernelHeight:(NSUInteger)kernelHeight {
  cv::Mat1f weightsAsOneRow = weights.reshape(1, 1);
  cv::Mat1f blockDiagonalWeights =
      cv::Mat1f::zeros(1, (int)(channels * kernelHeight * kernelWidth * 4));

  for (int channel = 0; channel < (int)channels; ++channel) {
    for (int kernelY = 0; kernelY < (int)kernelHeight; ++kernelY) {
      for (int kernelX = 0; kernelX < (int)kernelWidth; ++kernelX) {
        int indexInDiagonalMatrix = (int)(channel * kernelHeight * kernelWidth +
                                          kernelY * kernelWidth + kernelX);
        int indexInBlockDiagonalMatrix = 4 * indexInDiagonalMatrix + (channel % 4);
        blockDiagonalWeights.at<float>(indexInBlockDiagonalMatrix) =
            weightsAsOneRow.at<float>(indexInDiagonalMatrix);
      }
    }
  }

  return blockDiagonalWeights;
}

+ (BOOL)pnk_doesSupportActivationType:(pnk::ActivationType)activationType {
  return (activationType == pnk::ActivationTypeIdentity) ||
      [MPSCNNNeuron pnk_doesSupportActivationType:activationType];
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
