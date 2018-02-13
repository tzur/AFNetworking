// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

/// Creates a compute pipeline state for a given function.
///
/// @param functionName Name of the kernel to compile into the pipeline state.
///
/// @note This creates a non-specialized kernel function. Raises \c NSInternalInconsistencyException
/// if the kernel with \c functionName has constants.
id<MTLComputePipelineState> PNKCreateComputeState(id<MTLDevice> device, NSString *functionName)
    API_AVAILABLE(ios(10.0));

/// MTLFunctionConstantValues is not supported in simulator for Xcode 8. Solved in Xcode 9.
#if PNK_USE_MPS

/// Creates a compute pipeline state for a given function specialized for the given constants.
///
/// @param functionName Name of the kernel to compile into the pipeline state.
/// @param constants Constant values to set in the kernel. Used to compile a specialized version of
/// the kernel.
///
/// @note This creates a specialized kernel function.
id<MTLComputePipelineState> PNKCreateComputeStateWithConstants(id<MTLDevice> device,
    NSString *functionName, MTLFunctionConstantValues *constants) API_AVAILABLE(ios(10.0));

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
