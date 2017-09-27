// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

namespace pnk {
  struct ActivationKernelModel;
}

#if PNK_USE_MPS

@class MPSCNNNeuron;

/// Category for conveniently creating \c MPSCNNNeuron objects from pinky \c ActivationKernelModel.
@interface MPSCNNNeuron (Factory)

/// Returns \c MPSCNNNeuron representing the activation function described by \c activationModel.
/// Returns \c nil if \c activationModel activation type is \c ActivationTypeIdentity or an unknown
/// type.
+ (MPSCNNNeuron * _Nullable)pnk_cnnNeuronWithDevice:(id<MTLDevice>)device
    activationModel:(const pnk::ActivationKernelModel &)activationModel;

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
