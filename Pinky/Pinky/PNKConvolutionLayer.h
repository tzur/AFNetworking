// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKKernel.h"

NS_ASSUME_NONNULL_BEGIN

namespace pnk {
  struct ActivationKernelModel;
  struct ConvolutionKernelModel;
}

/// Layer performing a convolution operation.
///
/// @note Provides partial support of channel grouping (a.k.a. depthwise convolution). If number of
/// channel groups is more than one then this number is required to be equal to both input channels
/// count and output channels count. Moreover, it is required to be divisible by 4.
@interface PNKConvolutionLayer : NSObject <PNKUnaryKernel>

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

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
