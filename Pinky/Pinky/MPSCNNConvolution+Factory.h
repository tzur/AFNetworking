// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKNeuralNetworkTypeDefinitions.h"

NS_ASSUME_NONNULL_BEGIN

namespace pnk {
  struct ActivationKernelModel;
  struct ConvolutionKernelModel;
}

#if PNK_USE_MPS

/// Category for conveniently creating \c MPSCNNConvolution objects from pinky model structs.
@interface MPSCNNConvolution (Factory)

/// Returns \c MPSCNNConvolution that performs the convolution represented by \c convolutionModel
/// with the activation represented by \c activationModel.
///
/// @note This is a memory intensive operation and requires allocating \c MTLBuffers for the
/// parameters of the convolution.
+ (MPSCNNConvolution *)pnk_cnnConvolutionWithDevice:(id<MTLDevice>)device
    convolutionModel:(const pnk::ConvolutionKernelModel &)convolutionModel
    activationModel:(const pnk::ActivationKernelModel &)activationModel;

/// Returns \c YES if the given \c activationType is supported by this class.
+ (BOOL)pnk_doesSupportActivationType:(pnk::ActivationType)activationType;

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
