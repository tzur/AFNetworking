// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKNetworkSchemeFactory.h"
#import "PNKNeuralNetwork.h"

NS_ASSUME_NONNULL_BEGIN

/// Neural network implementation running the underlying \c pnk::NetworkScheme using a collection of
/// input images to produce a collection of output images.
@interface PNKRunnableNeuralNetwork : NSObject <PNKNeuralNetwork>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the network with \c networkScheme.
- (instancetype)initWithNetworkScheme:(const pnk::NetworkScheme &)networkScheme;

/// Encodes the entire set of operations performed by the neural network onto \c buffer.
/// \c inputImages is a collection of input images mapped by their names. All input images of type
/// \c MPSTemporaryImage have their \c readCount property decremented by \c 1 after this method
/// finishes. \c outputImages is a collection of output images mapped by their names. This method
/// cannot be used when the network has input parameters (non-images) in addition to input images.
- (void)encodeWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                    inputImages:(NSDictionary<NSString *, MPSImage *> *)inputImages
                   outputImages:(NSDictionary<NSString *, MPSImage *> *)outputImages;

/// Encodes the entire set of operations performed by the neural network onto \c commandBuffer.
/// This method must be used when the network has input parameters (non-images) in addition to input
/// images. \c inputImages is a collection of input images mapped by their names. All input images
/// of type \c MPSTemporaryImage have their \c readCount property decremented by \c 1 after this
/// method finishes. \c inputParameters is a collection of input parameters mapped by their names.
/// \c outputImages is a collection of output images mapped by their names.
- (void)encodeWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                    inputImages:(NSDictionary<NSString *, MPSImage *> *)inputImages
                inputParameters:(NSDictionary<NSString *, NSObject *> *)inputParameters
                   outputImages:(NSDictionary<NSString *, MPSImage *> *)outputImages;

/// Calculates output image sizes from the given \c inputImageSizes. Both \c inputImageSizes and the
/// return value are dictionaries with keys being image names and values being image sizes.
- (std::unordered_map<std::string, MTLSize>)outputImageSizesFromInputImageSizes:
    (const std::unordered_map<std::string, MTLSize> &)inputImageSizes;

@end

NS_ASSUME_NONNULL_END
