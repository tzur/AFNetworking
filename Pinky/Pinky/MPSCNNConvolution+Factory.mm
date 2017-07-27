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
  MPSCNNNeuron *neuronActivation = [MPSCNNNeuron pnk_cnnNeuronWithDevice:device
                                                         activationModel:activationModel];
  MPSCNNConvolutionDescriptor *convolutionDescriptor =
      [MPSCNNConvolutionDescriptor
       cnnConvolutionDescriptorWithKernelWidth:convolutionModel.kernelWidth
       kernelHeight:convolutionModel.kernelHeight
       inputFeatureChannels:convolutionModel.inputFeatureChannels
       outputFeatureChannels:convolutionModel.outputFeatureChannels
       neuronFilter:neuronActivation];

  convolutionDescriptor.strideInPixelsX = convolutionModel.strideX;
  convolutionDescriptor.strideInPixelsY = convolutionModel.strideY;
  convolutionDescriptor.groups = convolutionModel.groups;

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

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
