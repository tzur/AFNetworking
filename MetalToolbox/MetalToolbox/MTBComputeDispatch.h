// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

/// Dispatches a GPU operation to a compute command encoder. Uses default thread group size.
///
/// @param state Reference to a compiled compute program to encode and dispatch.
/// @param commandBuffer Command buffer to store the encoded command.
/// @param buffers Array of buffers to encode. The buffers are encoded to an index corresponding to
/// their index in the array.
/// @param inputImages Array of input images to encode. The textures of the images are encoded to an
/// index corresponding to their index in the array. All images of type \c MTLTemporaryImage have
/// their \c readCount property decremented by \c 1 after encoding.
/// @param outputImages Array of output images to encode. The textures of output images are encoded
/// in their order after the textures of the input images, so if you transfer to this API 2 input
/// images and 1 output image - the input textures will get indices 0 and 1 and the output image
/// will get index 2.
/// @param commandDescription Debug string label used to identify groups of encoded commands.
/// If \c nil then no label will be added. Adding a label does not change the rendering or compute
/// behavior, rather it is used by the Xcode debugger to organize the rendering commands in a format
/// that may provide insight into how your compute pipeline works.
/// @param workingSpaceSize Working space dimensions for the kernel threads to be executed on. Must
/// be larger than 0 in all dimensions.
///
/// @note We want to maximize the number of threads running in parallel. Thus, \c threadsInGroup is
/// set as follows:
///
/// \c width is set to \c state.threadExecutionWidth
///
/// \c height is set such that the number of threads in a group is set to the maximum number of
/// threads.
///
/// \c depth is set to 1.
///
/// The number of thread groups (grid cells) is set such that the entire working space is covered.
void MTBComputeDispatchWithDefaultThreads(id<MTLComputePipelineState> state,
                                          id<MTLCommandBuffer> commandBuffer,
                                          NSArray<id<MTLBuffer>> *buffers,
                                          NSArray<MPSImage *> *inputImages,
                                          NSArray<MPSImage *> *outputImages,
                                          NSString * _Nullable commandDescription,
                                          MTLSize workingSpaceSize);

/// Dispatches a GPU operation working only on \c MTLBuffers to a compute command encoder. Uses
/// default thread group size.
///
/// @param state Reference to a compiled compute program to encode and dispatch.
/// @param commandBuffer Command buffer to store the encoded command.
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
/// (grid cells) is chosen such that entire working buffer is covered.
void MTBComputeDispatchWithDefaultThreads(id<MTLComputePipelineState> state,
                                          id<MTLCommandBuffer> commandBuffer,
                                          NSArray<id<MTLBuffer>> *buffers,
                                          NSString * _Nullable commandDescription,
                                          NSUInteger workingBufferSize);

/// Dispatches a GPU operation working only on \c MPSImages to a compute command encoder. Uses
/// default thread group size.
///
/// @param state Reference to a compiled compute program to encode and dispatch.
/// @param commandBuffer Buffer to store the encoded command.
/// @param inputImages Array of input images to encode. The textures of the images are encoded to an
/// index corresponding to their index in the array. All images of type \c MTLTemporaryImage have
/// their \c readCount property decremented by \c 1 after encoding.
/// @param outputImages Array of output images to encode. The textures of output images are encoded
/// in their order after the textures of the input images, so if you transfer to this API 2 input
/// images and 1 output image - the input textures will get indices 0 and 1 and the output image
/// will get index 2.
/// @param commandDescription Debug string label used to identify groups of encoded commands.
/// If \c nil then no label will be added. Adding a label does not change the rendering or compute
/// behavior, rather it is used by the Xcode debugger to organize the rendering commands in a format
/// that may provide insight into how your compute pipeline works.
/// @param workingSpaceSize Working space dimensions for the kernel threads to be executed on. Must
/// be larger than 0 in all dimensions.
///
/// @note We want to maximize the number of threads running in parallel. Thus, \c threadsInGroup is
/// set as follows:
///
/// \c width is set to \c state.threadExecutionWidth.
///
/// \c height is set such that the number of threads in a group is set to the maximum number of
/// threads.
/// \c depth is set to 1.
///
/// The number of thread groups (grid cells) is set such that the entire working space is covered.
void MTBComputeDispatchWithDefaultThreads(id<MTLComputePipelineState> state,
                                          id<MTLCommandBuffer> commandBuffer,
                                          NSArray<MPSImage *> *inputImages,
                                          NSArray<MPSImage *> *outputImages,
                                          NSString * _Nullable commandDescription,
                                          MTLSize workingSpaceSize);

/// Dispatches a GPU operation to a compute command encoder. Thread group size is provided by the
/// caller.
///
/// @param state Reference to a compiled compute program to encode and dispatch.
/// @param commandBuffer Buffer to store the encoded command.
/// @param buffers Array of buffers to encode. The buffers are encoded to an index corresponding to
/// their index in the array.
/// @param inputImages Array of input images to encode. The textures of the images are encoded to an
/// index corresponding to their index in the array. All images of type \c MTLTemporaryImage have
/// their \c readCount property decremented by \c 1 after encoding.
/// @param outputImages Array of output images to encode. The textures of output images are encoded
/// in their order after the textures of the input images, so if you transfer to this API 2 input
/// images and 1 output image - the input textures will get indices 0 and 1 and the output image
/// will get index 2.
/// @param commandDescription Debug string label used to identify groups of encoded commands.
/// If \c nil then no label will be added. Adding a label does not change the rendering or compute
/// behavior, rather it is used by the Xcode debugger to organize the rendering commands in a format
/// that may provide insight into how your compute pipeline works.
/// @param threadsInGroup Number of threads in one thread group in each dimension. Must be larger
/// than 0 in all dimensions. Total count of threads in group must be less than or equal to
/// \c state.maxTotalThreadsPerThreadgroup.
/// @param threadgroupsPerGrid Number of thread groups (cells) in the grid of the texture to
/// compute. Must be larger than 0 in all dimensions.
void MTBComputeDispatch(id<MTLComputePipelineState> state, id<MTLCommandBuffer> commandBuffer,
                        NSArray<id<MTLBuffer>> *buffers, NSArray<MPSImage *> *inputImages,
                        NSArray<MPSImage *> *outputImages, NSString * _Nullable commandDescription,
                        MTLSize threadsInGroup, MTLSize threadgroupsPerGrid);

/// Dispatches a GPU operation working only on \c MTLBuffers to a compute command encoder. Thread
/// group size is provided by the caller.
///
/// @param state Reference to a compiled compute program to encode and dispatch.
/// @param commandBuffer Buffer to store the encoded command.
/// @param buffers Array of buffers to encode. The buffers are encoded to an index corresponding to
/// their index in the array.
/// @param commandDescription Debug string label used to identify groups of encoded commands.
/// If \c nil then no label will be added. Adding a label does not change the rendering or compute
/// behavior, rather it is used by the Xcode debugger to organize the rendering commands in a format
/// that may provide insight into how your compute pipeline works.
/// @param threadsInGroup Number of threads in one thread group in each dimension. Must be larger
/// than 0 in all dimensions. Total count of threads in group must be less than or equal to
/// \c state.maxTotalThreadsPerThreadgroup.
/// @param threadgroupsPerGrid Number of thread groups (cells) in the grid of the texture to
/// compute. Must be larger than 0 in all dimensions.
void MTBComputeDispatch(id<MTLComputePipelineState> state, id<MTLCommandBuffer> commandBuffer,
                        NSArray<id<MTLBuffer>> *buffers, NSString * _Nullable commandDescription,
                        MTLSize threadsInGroup, MTLSize threadgroupsPerGrid);

/// Dispatches a GPU operation working only on \c MPSImages to a compute command encoder. Thread
/// group size is provided by the caller.
///
/// @param state Reference to a compiled compute program to encode and dispatch.
/// @param commandBuffer Buffer to store the encoded command.
/// @param inputImages Array of input images to encode. The textures of the images are encoded to an
/// index corresponding to their index in the array. All images of type \c MTLTemporaryImage have
/// their \c readCount property decremented by \c 1 after encoding.
/// @param outputImages Array of output images to encode. The textures of output images are encoded
/// in their order after the textures of the input images, so if you transfer to this API 2 input
/// images and 1 output image - the input textures will get indices 0 and 1 and the output image
/// will get index 2.
/// @param commandDescription Debug string label used to identify groups of encoded commands.
/// If \c nil then no label will be added. Adding a label does not change the rendering or compute
/// behavior, rather it is used by the Xcode debugger to organize the rendering commands in a format
/// that may provide insight into how your compute pipeline works.
/// @param workingSpaceSize Working space dimensions for the kernel threads to be executed on. Must
/// be larger than 0 in all dimensions.
/// @param threadsInGroup Number of threads in one thread group in each dimension. Must be larger
/// than 0 in all dimensions. Total count of threads in group must be less than or equal to
/// \c state.maxTotalThreadsPerThreadgroup.
/// @param threadgroupsPerGrid Number of thread groups (cells) in the grid of the texture to
/// compute. Must be larger than 0 in all dimensions.
void MTBComputeDispatch(id<MTLComputePipelineState> state, id<MTLCommandBuffer> commandBuffer,
                        NSArray<MPSImage *> *inputImages, NSArray<MPSImage *> *outputImages,
                        NSString * _Nullable commandDescription, MTLSize threadsInGroup,
                        MTLSize threadgroupsPerGrid);

NS_ASSUME_NONNULL_END
