// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "PNKKernel.h"
#import "PNKNeuralNetworkTypeDefinitions.h"

NS_ASSUME_NONNULL_BEGIN

namespace pnk {
  struct UnaryFunctionKernelModel;
}

/// Layer applying unary function to each element of a tensor. Elements are scaled and shifted
/// first.
@interface PNKUnaryFunctionLayer : NSObject <PNKUnaryKernel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new layer that runs on \c device and performs a unary operation as defined by
/// \c unaryModel.
- (instancetype)initWithDevice:(id<MTLDevice>)device
                    unaryModel:(const pnk::UnaryFunctionKernelModel &)unaryModel
NS_DESIGNATED_INITIALIZER;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputImage as
/// input. Output is written asynchronously to \c outputImage. \c outputImage must be the same size
/// and number of channels as \c inputImage.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage outputImage:(MPSImage *)outputImage;
@end

NS_ASSUME_NONNULL_END
