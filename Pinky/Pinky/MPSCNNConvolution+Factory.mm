// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "MPSCNNConvolution+Factory.h"

#import "MPSCNNNeuron+Factory.h"
#import "PNKNeuralNetworkOperationsModel.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@implementation MPSCNNConvolution (Factory)

+ (MPSCNNConvolution *)pnk_cnnConvolutionWithDevice:(id<MTLDevice>)device
    convolutionModel:(const pnk::ConvolutionKernelModel &)convolutionModel
    activationModel:(const pnk::ActivationKernelModel &)activationModel {
  [self validateConvolutionModelGroups:convolutionModel];
  [self validateConvolutionModelWeights:convolutionModel];

  cv::Mat kernelWeightsMat = convolutionModel.kernelWeights;

  MPSCNNConvolutionDescriptor *convolutionDescriptor;
  if (@available(iOS 11.0, *)) {
    if (convolutionModel.groups == 1) {
      convolutionDescriptor = [MPSCNNConvolutionDescriptor
                               cnnConvolutionDescriptorWithKernelWidth:convolutionModel.kernelWidth
                               kernelHeight:convolutionModel.kernelHeight
                               inputFeatureChannels:convolutionModel.inputFeatureChannels
                               outputFeatureChannels:convolutionModel.outputFeatureChannels];
    } else {
      convolutionDescriptor = [MPSCNNDepthWiseConvolutionDescriptor
                               cnnConvolutionDescriptorWithKernelWidth:convolutionModel.kernelWidth
                               kernelHeight:convolutionModel.kernelHeight
                               inputFeatureChannels:convolutionModel.inputFeatureChannels
                               outputFeatureChannels:convolutionModel.outputFeatureChannels];
    }

    [self updateConvolutionDescriptor:convolutionDescriptor withActivationModel:activationModel];

    convolutionDescriptor.dilationRateX = convolutionModel.dilationX;
    convolutionDescriptor.dilationRateY = convolutionModel.dilationY;
  } else {
    MPSCNNNeuron *neuronActivation = [MPSCNNNeuron pnk_cnnNeuronWithDevice:device
                                                           activationModel:activationModel];
    convolutionDescriptor = [MPSCNNConvolutionDescriptor
                             cnnConvolutionDescriptorWithKernelWidth:convolutionModel.kernelWidth
                             kernelHeight:convolutionModel.kernelHeight
                             inputFeatureChannels:convolutionModel.inputFeatureChannels
                             outputFeatureChannels:convolutionModel.outputFeatureChannels
                             neuronFilter:neuronActivation];
    if (convolutionModel.groups > 1) {
      convolutionDescriptor.groups = convolutionModel.groups / 4;
      kernelWeightsMat = [self blockDiagonalWeightsFromWeights:convolutionModel.kernelWeights
                                                      channels:convolutionModel.inputFeatureChannels
                                                   kernelWidth:convolutionModel.kernelWidth
                                                  kernelHeight:convolutionModel.kernelHeight];
    }
  }

  convolutionDescriptor.strideInPixelsX = convolutionModel.strideX;
  convolutionDescriptor.strideInPixelsY = convolutionModel.strideY;

  float *kernelWeights = (float *)(kernelWeightsMat.data);
  float * _Nullable biasWeights = convolutionModel.hasBias ?
      (float *)(convolutionModel.biasWeights.data) : nil;

  return [[MPSCNNConvolution alloc] initWithDevice:device
                             convolutionDescriptor:convolutionDescriptor kernelWeights:kernelWeights
                                         biasTerms:biasWeights flags:MPSCNNConvolutionFlagsNone];
}

+ (void)updateConvolutionDescriptor:(MPSCNNConvolutionDescriptor *)convolutionDescriptor
                withActivationModel:(const pnk::ActivationKernelModel &)activationModel {
  if (@available(iOS 11.0, *)) {
    switch (activationModel.activationType) {
      case pnk::ActivationTypeIdentity:
        break;
      case pnk::ActivationTypeAbsolute:
        [convolutionDescriptor setNeuronType:MPSCNNNeuronTypeAbsolute parameterA:0 parameterB:0];
        break;
      case pnk::ActivationTypeReLU:
        [convolutionDescriptor setNeuronType:MPSCNNNeuronTypeReLU parameterA:0 parameterB:0];
        break;
      case pnk::ActivationTypeLeakyReLU:
        [convolutionDescriptor setNeuronType:MPSCNNNeuronTypeReLU
                                  parameterA:activationModel.alpha(0) parameterB:0];
        break;
      case pnk::ActivationTypeTanh:
        [convolutionDescriptor setNeuronType:MPSCNNNeuronTypeTanH parameterA:1 parameterB:1];
        break;
      case pnk::ActivationTypeScaledTanh:
        [convolutionDescriptor setNeuronType:MPSCNNNeuronTypeTanH
                                  parameterA:activationModel.alpha(0)
                                  parameterB:activationModel.beta(0)];
        break;
      case pnk::ActivationTypeSigmoid:
        [convolutionDescriptor setNeuronType:MPSCNNNeuronTypeSigmoid parameterA:0 parameterB:0];
        break;
      case pnk::ActivationTypeSigmoidHard:
        [convolutionDescriptor setNeuronType:MPSCNNNeuronTypeHardSigmoid
                                  parameterA:activationModel.alpha(0)
                                  parameterB:activationModel.beta(0)];
        break;
      case pnk::ActivationTypeLinear:
        [convolutionDescriptor setNeuronType:MPSCNNNeuronTypeLinear
                                  parameterA:activationModel.alpha(0)
                                  parameterB:activationModel.beta(0)];
        break;
      case pnk::ActivationTypePReLU: {
        LTParameterAssert(activationModel.alpha.isContinuous(), @"Activation model's alpha "
                          "parameters matrix must be continuous");
        NSUInteger totalBytes = (NSUInteger)activationModel.alpha.total() *
            activationModel.alpha.elemSize();
        NSData *alphaData = [NSData dataWithBytesNoCopy:activationModel.alpha.data length:totalBytes
                                           freeWhenDone:NO];
        [convolutionDescriptor setNeuronToPReLUWithParametersA:alphaData];
      } break;
      case pnk::ActivationTypeELU:
        [convolutionDescriptor setNeuronType:MPSCNNNeuronTypeELU
                                  parameterA:activationModel.alpha(0)
                                  parameterB:0];
        break;
      case pnk::ActivationTypeSoftsign:
        [convolutionDescriptor setNeuronType:MPSCNNNeuronTypeSoftSign parameterA:0 parameterB:0];
        break;
      case pnk::ActivationTypeSoftplus:
        [convolutionDescriptor setNeuronType:MPSCNNNeuronTypeSoftPlus parameterA:1 parameterB:1];
        break;
      case pnk::ActivationTypeParametricSoftplus:
        [convolutionDescriptor setNeuronType:MPSCNNNeuronTypeSoftPlus
                                  parameterA:activationModel.alpha(0)
                                  parameterB:activationModel.beta(0)];
        break;
    }
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
