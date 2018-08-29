// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

@class MTBFunctionConstant;

/// Creates a compute pipeline state for a given function specialized for the given constants when
/// provided.
///
/// @param functionName Name of the kernel to compile into the pipeline state.
/// @param constants Constant values to set in the kernel. Used to compile a specialized version of
/// the kernel when provided.
id<MTLComputePipelineState> PNKCreateComputeState(id<MTLDevice> device,
    NSString * const functionName, NSArray<MTBFunctionConstant *> * _Nullable constants = nil);

NS_ASSUME_NONNULL_END
