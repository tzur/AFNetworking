// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKNeuralNetworkTypeDefinitions.h"

NS_ASSUME_NONNULL_BEGIN

namespace pnk {
  struct ActivationKernelModel;
}

/// Category for conveniently creating \c MPSCNNNeuron objects from pinky \c ActivationKernelModel.
API_AVAILABLE(ios(10.0))
@interface MPSCNNNeuron (Factory)

/// Returns \c MPSCNNNeuron representing the activation function described by \c activationModel.
/// Returns \c nil if \c activationModel activation type is \c ActivationTypeIdentity or an unknown
/// type.
+ (MPSCNNNeuron * _Nullable)pnk_cnnNeuronWithDevice:(id<MTLDevice>)device
    activationModel:(const pnk::ActivationKernelModel &)activationModel;

/// Returns \c YES if the given \c activationType is supported by this class.
+ (BOOL)pnk_doesSupportActivationType:(pnk::ActivationType)activationType;

@end

NS_ASSUME_NONNULL_END
