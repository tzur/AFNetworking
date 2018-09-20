// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKNeuralNetworkTypeDefinitions.h"

NS_ASSUME_NONNULL_BEGIN

namespace pnk {
  struct ActivationKernelModel;
  struct ConvolutionKernelModel;
}

/// Category for conveniently creating \c MPSCNNConvolution objects from pinky model structs.
@interface MPSCNNConvolution (Factory)

/// Returns \c MPSCNNConvolution that performs the convolution represented by \c convolutionModel
/// with the activation represented by \c activationModel.
///
/// @note Depthwise convolution (<tt>groups == inputFeatureChannels</tt>) is supported in case when
/// \t inputFeatureChannels, \t outputFeatureChannels and \t groups are all equal and divisible by
/// \c 4. The latter constraint is due to iOS 10's requirement that each group has a number of
/// channels that is divisible by \t 4.
+ (MPSCNNConvolution *)pnk_cnnConvolutionWithDevice:(id<MTLDevice>)device
    convolutionModel:(const pnk::ConvolutionKernelModel &)convolutionModel
    activationModel:(const pnk::ActivationKernelModel &)activationModel;

/// Returns \c YES if the given \c activationType is supported by this class.
+ (BOOL)pnk_doesSupportActivationType:(pnk::ActivationType)activationType;

@end

NS_ASSUME_NONNULL_END
