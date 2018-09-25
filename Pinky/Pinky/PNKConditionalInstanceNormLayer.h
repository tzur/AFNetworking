// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKNeuralKernel.h"

NS_ASSUME_NONNULL_BEGIN

namespace pnk {
  struct ActivationKernelModel;
  struct NormalizationKernelModel;
}

/// Layer performing a conditional instance normalization operation.
@interface PNKConditionalInstanceNormLayer : NSObject <PNKNeuralKernel, PNKParametricUnaryKernel>

/// Initializes a new layer that runs on \c device and performs a conditional instance normalization
/// operation such that each condition parameters are described by their index in
/// \c normalizationModels. The activation function described by \c activationModel follows all
/// conditions.
- (instancetype)initWithDevice:(id<MTLDevice>)device
            normalizationModel:(const pnk::NormalizationKernelModel &)normalizationModel
               activationModel:(const pnk::ActivationKernelModel &)activationModel
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// Encodes the operation performed by the kernel to \c commandBuffer using \c inputImage as
/// input. \c inputParameters must be a dictionary containing the condition number to be used by
/// this instance normalization layer. It must contain a single key-value pair with a key
/// @"condition" and an \c NSNumber value for the condition number. Output is written asynchronously
/// to \c outputImage. \c outputImage must be the same size and number of channels as \c inputImage.
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                   inputImage:(MPSImage *)inputImage
              inputParameters:(NSDictionary<NSString *, NSObject *> *)inputParameters
                  outputImage:(MPSImage *)outputImage;

/// Number of conditions applicable in this layer.
@property (readonly, nonatomic) NSUInteger conditionsCount;

@end

NS_ASSUME_NONNULL_END
