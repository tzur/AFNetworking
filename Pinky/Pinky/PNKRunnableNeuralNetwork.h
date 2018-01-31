// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKNetworkSchemeFactory.h"
#import "PNKNeuralNetwork.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Neural network implementation running the underlying \c pnk::NetworkScheme using a collection of
/// input images to produce a collection of output images.
@interface PNKRunnableNeuralNetwork : NSObject <PNKNeuralNetwork>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the network with \c networkScheme.
- (instancetype)initWithNetworkScheme:(const pnk::NetworkScheme &)networkScheme;

/// Encodes the entire set of operations performed by the neural network onto \c buffer.
/// \c inputImages is a collection of input images mapped by their names. \c outputImages is a
/// collection of output images mapped by their names. All input images of type \c MPSTemporaryImage
/// have their \c readCount property decremented by \c 1 after this method finishes.
- (void)encodeWithCommandBuffer:(id<MTLCommandBuffer>)buffer
                    inputImages:(NSDictionary<NSString *, MPSImage *> *)inputImages
                   outputImages:(NSDictionary<NSString *, MPSImage *> *)outputImages;

@end

#endif

NS_ASSUME_NONNULL_END
