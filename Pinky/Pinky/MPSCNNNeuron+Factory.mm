// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "MPSCNNNeuron+Factory.h"

#import "PNKNeuralNetworkOperationsModel.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

static const NSDictionary *PNKActivationTypeToNeuronClass() {
  if (@available(iOS 11.0, *)) {
    return @{
      @(pnk::ActivationTypeAbsolute): [MPSCNNNeuronAbsolute class],
      @(pnk::ActivationTypeReLU): [MPSCNNNeuronReLU class],
      @(pnk::ActivationTypeLeakyReLU): [MPSCNNNeuronReLU class],
      @(pnk::ActivationTypeTanh): [MPSCNNNeuronTanH class],
      @(pnk::ActivationTypeScaledTanh): [MPSCNNNeuronTanH class],
      @(pnk::ActivationTypeSigmoid): [MPSCNNNeuronSigmoid class],
      @(pnk::ActivationTypeSigmoidHard): [MPSCNNNeuronHardSigmoid class],
      @(pnk::ActivationTypeLinear): [MPSCNNNeuronLinear class],
      @(pnk::ActivationTypePReLU): [MPSCNNNeuronPReLU class],
      @(pnk::ActivationTypeELU): [MPSCNNNeuronELU class],
      @(pnk::ActivationTypeSoftsign): [MPSCNNNeuronSoftSign class],
      @(pnk::ActivationTypeSoftplus): [MPSCNNNeuronSoftPlus class],
      @(pnk::ActivationTypeParametricSoftplus): [MPSCNNNeuronSoftPlus class]
    };
  } else {
    return @{
      @(pnk::ActivationTypeAbsolute): [MPSCNNNeuronAbsolute class],
      @(pnk::ActivationTypeReLU): [MPSCNNNeuronReLU class],
      @(pnk::ActivationTypeLeakyReLU): [MPSCNNNeuronReLU class],
      @(pnk::ActivationTypeTanh): [MPSCNNNeuronTanH class],
      @(pnk::ActivationTypeScaledTanh): [MPSCNNNeuronTanH class],
      @(pnk::ActivationTypeSigmoid): [MPSCNNNeuronSigmoid class],
      @(pnk::ActivationTypeLinear): [MPSCNNNeuronLinear class]
    };
  }
}

static const NSDictionary *kActivationTypeToNeuronClass = PNKActivationTypeToNeuronClass();

@implementation MPSCNNNeuron (Factory)

+ (MPSCNNNeuron * _Nullable)pnk_cnnNeuronWithDevice:(id<MTLDevice>)device
    activationModel:(const pnk::ActivationKernelModel &)activationModel {
  if (activationModel.activationType == pnk::ActivationTypeIdentity) {
    return nil;
  }

  Class neuronClass = kActivationTypeToNeuronClass[@(activationModel.activationType)];

  LTParameterAssert(neuronClass, @"Activation type %lu is not supported",
                    (unsigned long)activationModel.activationType);

  switch (activationModel.activationType) {
    case pnk::ActivationTypeIdentity:
      return nil;
    case pnk::ActivationTypeAbsolute:
      return [[neuronClass alloc] initWithDevice:device];
    case pnk::ActivationTypeReLU:
      return [[neuronClass alloc] initWithDevice:device a:0];
    case pnk::ActivationTypeLeakyReLU:
      return [[neuronClass alloc] initWithDevice:device a:activationModel.alpha(0)];
    case pnk::ActivationTypeTanh:
      return [[neuronClass alloc] initWithDevice:device a:1 b:1];
    case pnk::ActivationTypeScaledTanh:
      return [[neuronClass alloc] initWithDevice:device a:activationModel.alpha(0)
                                               b:activationModel.beta(0)];
    case pnk::ActivationTypeSigmoid:
      return [[neuronClass alloc] initWithDevice:device];
    case pnk::ActivationTypeSigmoidHard:
        return [[neuronClass alloc] initWithDevice:device a:activationModel.alpha(0)
                                                          b:activationModel.beta(0)];
    case pnk::ActivationTypeLinear:
      return [[neuronClass alloc] initWithDevice:device a:activationModel.alpha(0)
                                                        b:activationModel.beta(0)];
    case pnk::ActivationTypePReLU:
        LTParameterAssert(activationModel.alpha.isContinuous(), @"Activation model's alpha "
                          "parameters matrix must be continuous");
        return [[neuronClass alloc] initWithDevice:device
                                                 a:(const float *)activationModel.alpha.data
                                             count:activationModel.alpha.total()];
    case pnk::ActivationTypeELU:
      return [[neuronClass alloc] initWithDevice:device a:activationModel.alpha(0)];
    case pnk::ActivationTypeSoftsign:
      return [[neuronClass alloc] initWithDevice:device];
    case pnk::ActivationTypeSoftplus:
      return [[neuronClass alloc] initWithDevice:device a:1 b:1];
    case pnk::ActivationTypeParametricSoftplus:
      LTParameterAssert(activationModel.alpha.total() == 1 && activationModel.beta.total() == 1,
                        @"Parametric Softplus activation with per-layer parameters is not "
                        "supported");
      return [[neuronClass alloc] initWithDevice:device a:activationModel.alpha(0)
                                               b:activationModel.beta(0)];
  }
}

+ (BOOL)pnk_doesSupportActivationType:(pnk::ActivationType)activationType {
  return [kActivationTypeToNeuronClass objectForKey:@(activationType)] != nil;
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
