// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

@protocol MTLCommandQueue, MTLDevice;

/// Returns the default Metal device. It is guaranteed to return the same device on all calls in an
/// application. To be compliant with the "Metal Best Practices Guide" please always use this
/// function instead of \c MTLCreateSystemDefaultDevice.
id<MTLDevice> LTMTLDefaultDevice();

/// Creates a single queue on the device returned by \c LTMTLDefaultDevice and then always returns
/// the queue that was created. The "Metal Best Practices Guide" calls for preferring this function
/// over \c newCommandQueue in cases where there's no differentiation between kinds of work the GPU
/// need to perform (for example, non-real-time compute processing and real-time graphics
/// rendering).
id<MTLCommandQueue> LTMTLDefaultCommandQueue();

NS_ASSUME_NONNULL_END
