// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

/// Creates a compute state on \c device for function named \c functionName. The function must be
/// present in the test Metal library (as opposed to the production Metal library that should be
/// accessed with \c PNKCreateComputeState).
id<MTLComputePipelineState> PNKCreateTestComputeState(id<MTLDevice> device, NSString *functionName);

NS_ASSUME_NONNULL_END
