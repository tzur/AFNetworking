// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKNeuralKernel.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Layer performing the elementwise SoftMax operation.
@interface PNKSoftMaxLayer : NSObject <PNKUnaryNeuralKernel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new layer that runs on \c device and performs a SoftMax operation.
- (instancetype)initWithDevice:(id<MTLDevice>)device NS_DESIGNATED_INITIALIZER;

@end

#endif

NS_ASSUME_NONNULL_END
