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
    case pnk::ActivationTypeAbsolute:
      return [[MPSCNNNeuronAbsolute alloc] initWithDevice:device];
    case pnk::ActivationTypeReLU:
      return [[MPSCNNNeuronReLU alloc] initWithDevice:device a:0];
    case pnk::ActivationTypeLeakyReLU:
      return [[MPSCNNNeuronReLU alloc] initWithDevice:device a:activationModel.alpha(0)];
    case pnk::ActivationTypeTanh:
      return [[MPSCNNNeuronTanH alloc] initWithDevice:device a:1 b:1];
    case pnk::ActivationTypeScaledTanh:
      return [[MPSCNNNeuronTanH alloc] initWithDevice:device a:activationModel.alpha(0)
                                                    b:activationModel.beta(0)];
    case pnk::ActivationTypeSigmoid:
      return [[MPSCNNNeuronSigmoid alloc] initWithDevice:device];
    case pnk::ActivationTypeSigmoidHard:
      if(@available(iOS 11.0, *)) {
        return [[MPSCNNNeuronHardSigmoid alloc] initWithDevice:device a:activationModel.alpha(0)
                                                             b:activationModel.beta(0)];
      } else {
        LTParameterAssert(NO, @"iOS 10 does not support hard sigmoid activation");
      }
    case pnk::ActivationTypeLinear:
      return [[MPSCNNNeuronLinear alloc] initWithDevice:device a:activationModel.alpha(0)
                                                      b:activationModel.beta(0)];
    case pnk::ActivationTypePReLU:
      if(@available(iOS 11.0, *)) {
        LTParameterAssert(activationModel.alpha.isContinuous(), @"Activation model's alpha "
                          "parameters matrix must be continuous");
        return [[MPSCNNNeuronPReLU alloc] initWithDevice:device
                                                       a:(const float *)activationModel.alpha.data
                                                   count:activationModel.alpha.total()];
      } else {
        LTParameterAssert(NO, @"iOS 10 does not support PRELU activation");
      }
    case pnk::ActivationTypeELU:
      if(@available(iOS 11.0, *)) {
        return [[MPSCNNNeuronELU alloc] initWithDevice:device a:activationModel.alpha(0)];
      } else {
        LTParameterAssert(NO, @"iOS 10 does not support ELU activation");
      }
    case pnk::ActivationTypeSoftsign:
      if(@available(iOS 11.0, *)) {
        return [[MPSCNNNeuronSoftSign alloc] initWithDevice:device];
      } else {
        LTParameterAssert(NO, @"iOS 10 does not support Softsign activation");
      }
    case pnk::ActivationTypeSoftplus:
      if(@available(iOS 11.0, *)) {
        return [[MPSCNNNeuronSoftPlus alloc] initWithDevice:device a:1 b:1];
      } else {
        LTParameterAssert(NO, @"iOS 10 does not support Softplus activation");
      }
    case pnk::ActivationTypeParametricSoftplus:
      if(@available(iOS 11.0, *)) {
        if (activationModel.alpha.total() == 1 && activationModel.beta.total() == 1) {
          return [[MPSCNNNeuronSoftPlus alloc] initWithDevice:device a:activationModel.alpha(0)
                                                            b:activationModel.beta(0)];
        } else {
          LTParameterAssert(NO, @"Parametric Softplus activation with per-layer parameters is not "
                            "supported");
        }
      } else {
        LTParameterAssert(NO, @"iOS 10 does not support Parametric Softplus activation");
      }
  }
}

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
