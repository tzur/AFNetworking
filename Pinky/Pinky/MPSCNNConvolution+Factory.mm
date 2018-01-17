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
  MPSCNNConvolutionDescriptor *convolutionDescriptor;
  if (@available(iOS 11.0, *)) {
    convolutionDescriptor = [MPSCNNConvolutionDescriptor
                             cnnConvolutionDescriptorWithKernelWidth:convolutionModel.kernelWidth
                             kernelHeight:convolutionModel.kernelHeight
                             inputFeatureChannels:convolutionModel.inputFeatureChannels
                             outputFeatureChannels:convolutionModel.outputFeatureChannels];
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
        NSUInteger totalBytes = (NSUInteger )activationModel.alpha.total() *
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
  }

  convolutionDescriptor.strideInPixelsX = convolutionModel.strideX;
  convolutionDescriptor.strideInPixelsY = convolutionModel.strideY;
  convolutionDescriptor.groups = convolutionModel.groups;

  LTParameterAssert(convolutionModel.kernelWeights.total() ==
                    convolutionModel.outputFeatureChannels * convolutionModel.kernelHeight *
                    convolutionModel.kernelWidth * convolutionModel.inputFeatureChannels, @"The "
                    "kernel weights matrix must have %lu * %lu * %lu * %lu = %lu members, got %lu",
                    (unsigned long)convolutionModel.outputFeatureChannels,
                    (unsigned long)convolutionModel.kernelHeight,
                    (unsigned long)convolutionModel.kernelWidth,
                    (unsigned long)convolutionModel.inputFeatureChannels,
                    (unsigned long)(convolutionModel.outputFeatureChannels *
                                    convolutionModel.kernelHeight *
                                    convolutionModel.kernelWidth *
                                    convolutionModel.inputFeatureChannels),
                    convolutionModel.kernelWeights.total());
  LTParameterAssert(convolutionModel.kernelWeights.isContinuous(), @"Kernel weights in model must "
           "be continuous");
  LTParameterAssert(!convolutionModel.hasBias || convolutionModel.biasWeights.isContinuous(),
           @"Bias weights in model must be continuous");
  float *kernelWeights = (float *)(convolutionModel.kernelWeights.data);
  float * _Nullable biasWeights = convolutionModel.hasBias ?
      (float *)(convolutionModel.biasWeights.data) : nil;

  return [[MPSCNNConvolution alloc] initWithDevice:device
                             convolutionDescriptor:convolutionDescriptor kernelWeights:kernelWeights
                                         biasTerms:biasWeights flags:MPSCNNConvolutionFlagsNone];
}

+ (BOOL)pnk_doesSupportActivationType:(pnk::ActivationType)activationType {
  return (activationType == pnk::ActivationTypeIdentity) ||
      [MPSCNNNeuron pnk_doesSupportActivationType:activationType];
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
