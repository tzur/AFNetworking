// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

NS_ASSUME_NONNULL_BEGIN

/// Dispatches a GPU operation to a compute command encoder.
///
/// @param state Reference to a compiled compute program to encode and dispatch.
/// @param commandBuffer Buffer to store the encoded command.
/// @param buffers Array of buffers to encode. The buffers are encoded to an index corresponding to
/// their index in the array.
/// @param textures Array of textures to encode. The textures are encoded to an index corresponding
/// to their index in the array.
/// @param debugGroup Debug string label used to identify groups of encoded commands. If \c nil then
/// no label will be added. Adding a label does not change the rendering or compute behavior, rather
/// it is used by the Xcode debugger to organize the rendering commands in a format that may provide
/// insight into how your compute pipeline works.
/// @param workingSpaceSize Image dimensions for the kernel threads to be executed on. Must be
/// larger than 0 in all dimensions. \c workingSpaceSize.depth is expected to be divided by 4 since
/// \c MPSImage featureChannels are divided by 4 (RGBA). \c workingSpaceSize.depth should take into
/// account the \c numberOfImages in case of batch processing.
///
/// @note We want to maximize the number of threads running in parallel. Thus,
/// \c threadsInGroup.width is set to \c state.threadExecutionWidth and \c threadsInGroup.height is
/// set such that the volume of threads in a group is set to the maximum number of threads. The
/// number of thread groups (grid cells) is chosen such that the entire image is covered.
void PNKComputeDispatchWithDefaultThreads(id<MTLComputePipelineState> state,
                                          id<MTLCommandBuffer> commandBuffer,
                                          NSArray<id<MTLBuffer>> *buffers,
                                          NSArray<id<MTLTexture>> *textures,
                                          NSString * _Nullable commandDescription,
                                          MTLSize workingSpaceSize);

/// Dispatches a GPU operation wokring only on \c MTLBuffers to a compute command encoder.
///
/// @param state Reference to a compiled compute program to encode and dispatch.
/// @param commandBuffer Buffer to store the encoded command.
/// @param buffers Array of buffers to encode. The buffers are encoded to an index corresponding to
/// their index in the array.
/// @param commandDescription Debug string label used to identify groups of encoded commands. If
/// \c nil then no label will be added. Adding a label does not change the rendering or compute
/// behavior, rather it is used by the Xcode debugger to organize the rendering commands in a format
/// that may provide insight into how your compute pipeline works.
/// @param workingBufferSize number of pixels for the kernel threads to be executed on. Must be
/// larger than 0.
///
/// @note We want to maximize the number of threads running in parallel. Thus,
/// \c threadsInGroup.width is set to the maximum number of threads, and the number of thread groups
/// (grid cells) is chosen such that the entire buffer is covered.
void PNKComputeDispatchWithDefaultThreads(id<MTLComputePipelineState> state,
                                          id<MTLCommandBuffer> commandBuffer,
                                          NSArray<id<MTLBuffer>> *buffers,
                                          NSString * _Nullable commandDescription,
                                          NSUInteger workingBufferSize);

/// Dispatches a GPU operation to a compute command encoder.
///
/// @param state Reference to a compiled compute program to encode and dispatch.
/// @param commandBuffer Buffer to store the encoded command.
/// @param buffers Array of buffers to encode. The buffers are encoded to an index corresponding to
/// their index in the array.
/// @param textures Array of textures to encode. The textures are encoded to an index corresponding
/// to their index in the array.
/// @param debugGroup Debug string label used to identify groups of encoded commands. If \c nil then
/// no label will be added. Adding a label does not change the rendering or compute behavior, rather
/// it is used by the Xcode debugger to organize the rendering commands in a format that may provide
/// insight into how your compute pipeline works.
/// @param threadsInGroup Number of threads in one thread group in each dimension. Must be larger
/// than 0 in all dimensions. Should be less than or equal to the maximum total threads in group.
/// @param threadgroupsPerGrid Number of thread groups (cells) in the grid of the texture to
/// compute. Must be larger than 0 in all dimensions.
void PNKComputeDispatch(id<MTLComputePipelineState> state, id<MTLCommandBuffer> commandBuffer,
                        NSArray<id<MTLBuffer>> *buffers,
                        NSArray<id<MTLTexture>> *textures,
                        NSString * _Nullable debugGroup,
                        MTLSize threadsInGroup,
                        MTLSize threadgroupsPerGrid);

NS_ASSUME_NONNULL_END
