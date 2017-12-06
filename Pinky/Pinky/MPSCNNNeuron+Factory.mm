// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "MPSCNNNeuron+Factory.h"

#import "PNKNeuralNetworkOperationsModel.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

@implementation MPSCNNNeuron (Factory)

+ (MPSCNNNeuron * _Nullable)pnk_cnnNeuronWithDevice:(id<MTLDevice>)device
    activationModel:(const pnk::ActivationKernelModel &)activationModel {
  switch (activationModel.activationType) {
    case pnk::ActivationTypeIdentity:
      return nil;
    case pnk::ActivationTypeReLU:
      return [[MPSCNNNeuronReLU alloc] initWithDevice:device a:0];
    case pnk::ActivationTypeLeakyReLU:
      return [[MPSCNNNeuronReLU alloc] initWithDevice:device a:activationModel.alpha(0)];
    case pnk::ActivationTypeLinear:
      return [[MPSCNNNeuronLinear alloc] initWithDevice:device a:activationModel.alpha(0)
                                                      b:activationModel.beta(0)];
    case pnk::ActivationTypeTanh:
      return [[MPSCNNNeuronTanH alloc] initWithDevice:device a:activationModel.alpha(0)
                                                    b:activationModel.beta(0)];
    case pnk::ActivationTypeSigmoid:
      return [[MPSCNNNeuronSigmoid alloc] initWithDevice:device];
    case pnk::ActivationTypeAbsolute:
      return [[MPSCNNNeuronAbsolute alloc] initWithDevice:device];
    default:
      LogWarning(@"Neuron activation type %@ is not supported yet, replacing with identity",
                 @(activationModel.activationType));
      return nil;
  }
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
