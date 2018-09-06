// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "MPSCNNNeuron+Factory.h"

#import "PNKNeuralNetworkOperationsModel.h"

NS_ASSUME_NONNULL_BEGIN

@implementation MPSCNNNeuron (Factory)

+ (NSDictionary<NSNumber *, Class> *)pnk_activationTypeToNeuronClass {
  static NSDictionary<NSNumber *, Class> *mapping;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if (@available(iOS 11.0, *)) {
      mapping = @{
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
      mapping = @{
        @(pnk::ActivationTypeAbsolute): [MPSCNNNeuronAbsolute class],
        @(pnk::ActivationTypeReLU): [MPSCNNNeuronReLU class],
        @(pnk::ActivationTypeLeakyReLU): [MPSCNNNeuronReLU class],
        @(pnk::ActivationTypeTanh): [MPSCNNNeuronTanH class],
        @(pnk::ActivationTypeScaledTanh): [MPSCNNNeuronTanH class],
        @(pnk::ActivationTypeSigmoid): [MPSCNNNeuronSigmoid class],
        @(pnk::ActivationTypeLinear): [MPSCNNNeuronLinear class]
      };
    }
  });
  return mapping;
}

+ (MPSCNNNeuron * _Nullable)pnk_cnnNeuronWithDevice:(id<MTLDevice>)device
    activationModel:(const pnk::ActivationKernelModel &)activationModel {
  if (activationModel.activationType == pnk::ActivationTypeIdentity) {
    return nil;
  }

  Class neuronClass = self.pnk_activationTypeToNeuronClass[@(activationModel.activationType)];

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
  return self.pnk_activationTypeToNeuronClass[@(activationType)] != nil;
}

@end

NS_ASSUME_NONNULL_END
