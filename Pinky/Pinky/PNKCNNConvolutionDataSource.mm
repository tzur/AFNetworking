// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKCNNConvolutionDataSource.h"

#import "PNKNeuralNetworkOperationsModel.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@interface PNKCNNConvolutionDataSource ()

/// Convolution descriptor.
@property (readonly, nonatomic) MPSCNNConvolutionDescriptor *convolutionDescriptor;

@end

@implementation PNKCNNConvolutionDataSource {
  cv::Mat _weights;
  cv::Mat1f _biasTerms;
}

- (instancetype)initWithConvolutionModel:(const pnk::ConvolutionKernelModel &)convolutionModel
                         activationModel:(const pnk::ActivationKernelModel &)activationModel {
  if (self = [super init]) {
    _convolutionDescriptor = [self descriptorWithConvolutionModel:convolutionModel
                                                  activationModel:activationModel];
    _weights = convolutionModel.kernelWeights;
    _biasTerms = convolutionModel.hasBias ? convolutionModel.biasWeights : cv::Mat1f();
  }
  return self;
}

- (MPSCNNConvolutionDescriptor *)descriptorWithConvolutionModel:
    (const pnk::ConvolutionKernelModel &)convolutionModel
    activationModel:(const pnk::ActivationKernelModel &)activationModel {
  MPSCNNConvolutionDescriptor *convolutionDescriptor;
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
  convolutionDescriptor.strideInPixelsX = convolutionModel.strideX;
  convolutionDescriptor.strideInPixelsY = convolutionModel.strideY;

  return convolutionDescriptor;
}

- (void)updateConvolutionDescriptor:(MPSCNNConvolutionDescriptor *)convolutionDescriptor
                withActivationModel:(const pnk::ActivationKernelModel &)activationModel {
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

- (MPSDataType)dataType {
  switch (_weights.depth()) {
    case CV_16F:
      return MPSDataTypeFloat16;
    case CV_32F:
      return MPSDataTypeFloat32;
    default:
      LTAssert(NO, @"Weights matrix depth (%d) is not supported", _weights.depth());
  }
}

- (void * __nonnull)weights {
  return _weights.data;
}

- (float * __nullable)biasTerms {
  return _biasTerms.empty() ? nil : (float *)_biasTerms.data;
}

- (BOOL)load {
  return YES;
}

- (void)purge {
  _weights.release();
  _biasTerms.release();
}

- (NSString * __nullable)label {
  return @"";
}

- (MPSCNNConvolutionDescriptor * _Nonnull)descriptor {
  return self.convolutionDescriptor;
}

@end

#endif

NS_ASSUME_NONNULL_END
