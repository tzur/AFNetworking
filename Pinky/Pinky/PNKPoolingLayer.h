// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKNeuralKernel.h"

NS_ASSUME_NONNULL_BEGIN

namespace pnk {
  struct PoolingKernelModel;
}

/// Layer performing a pooling operation.
API_AVAILABLE(ios(10.0))
@interface PNKPoolingLayer : NSObject <PNKUnaryNeuralKernel>

/// Initializes a new layer that runs on \c device and performs a pooling operation described by
/// \c poolingModel. Currently supports Max and Average pooling.
- (instancetype)initWithDevice:(id<MTLDevice>)device
                  poolingModel:(const pnk::PoolingKernelModel &)poolingModel
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
