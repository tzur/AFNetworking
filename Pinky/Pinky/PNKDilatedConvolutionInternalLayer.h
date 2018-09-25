// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKNeuralKernel.h"

NS_ASSUME_NONNULL_BEGIN

namespace pnk {
  struct ActivationKernelModel;
  struct ConvolutionKernelModel;
}

/// Layer performing a dilated convolution operation.
@interface PNKDilatedConvolutionInternalLayer : NSObject <PNKUnaryNeuralKernel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new layer that runs on \c device and performs a convolution operation described by
/// \c convolutionModel followed by an activation function described by \c activationModel.
- (instancetype)initWithDevice:(id<MTLDevice>)device
              convolutionModel:(const pnk::ConvolutionKernelModel &)convolutionModel
               activationModel:(const pnk::ActivationKernelModel &)activationModel
    NS_DESIGNATED_INITIALIZER;

/// Convenience initializer that initializes a new layer that runs on \c device and performs a
/// convolution operation described by \c convolutionModel with no activation.
- (instancetype)initWithDevice:(id<MTLDevice>)device
              convolutionModel:(const pnk::ConvolutionKernelModel &)convolutionModel;

@end

NS_ASSUME_NONNULL_END
