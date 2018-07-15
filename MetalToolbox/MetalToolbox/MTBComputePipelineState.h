// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

@class MTBFunctionConstant;

/// Creates a compute pipeline state for a given function specialized for the \c constants when
/// provided. Raises \c NSInvalidArgumentException when either \c functionName could not be found
/// in \c library or a compute pipiline state cannot be created for that function. Validates names
/// and types of \c constants with names and types of function constants in Metal code.
///
/// @param library Metal library containing the function.
/// @param functionName Name of the Metal function to compile into the pipeline state.
/// @param constants Constant values to set in the kernel. When present they are used to compile a
/// specialized version of the kernel.
id<MTLComputePipelineState> MTBCreateComputePipelineState(id<MTLLibrary> library,
    NSString *functionName, NSArray<MTBFunctionConstant *> * _Nullable constants = nil);

/// Creates a compute pipeline state for a given function specialized for the \c constants. Raises
/// \c NSInvalidArgumentException when either \c functionName could not be found in \c library or a
/// compute pipiline state cannot be created for that function. \c constants are transfered to the
/// Metal engine as is, without any validation.
///
/// @param library Metal library containing the function.
/// @param functionName Name of the Metal function to compile into the pipeline state.
/// @param constants Constant values to set in the kernel. Used to compile a specialized version of
/// the kernel.
id<MTLComputePipelineState> MTBCreateComputePipelineState(id<MTLLibrary> library,
    NSString *functionName, MTLFunctionConstantValues *constants);

NS_ASSUME_NONNULL_END
