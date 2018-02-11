// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

/// Returns the default Metal device. It is guaranteed to return the same device on all calls in an
/// application. To be compliant with the "Metal Best Practices Guide" please always use this
/// function instead of \c MTLCreateSystemDefaultDevice.
id<MTLDevice> PNKDefaultDevice();

/// Creates a single queue on the device returned by \c PNKDefaultDevice and then always returns the
/// queue that was created.To be compliant with the "Metal Best Practices Guide" please always use
/// this function instead of \c newCommandQueue.
id<MTLCommandQueue> PNKDefaultCommandQueue();

NS_ASSUME_NONNULL_END
