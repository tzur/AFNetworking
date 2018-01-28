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

@end

#endif

NS_ASSUME_NONNULL_END
