// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Dispatches a GPU operation working only on \c MTLBuffers to a compute command encoder.
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
                                          NSArray<MPSImage *> *inputImages,
                                          NSArray<MPSImage *> *outputImages,
                                          NSString * _Nullable commandDescription,
                                          MTLSize workingSpaceSize) API_AVAILABLE(ios(10.0));

/// Dispatches a GPU operation working only on \c MPSImages to a compute command encoder.
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
                                          NSArray<MPSImage *> *inputImages,
                                          NSArray<MPSImage *> *outputImages,
                                          NSString * _Nullable commandDescription,
                                          MTLSize workingSpaceSize) API_AVAILABLE(ios(10.0));

/// Dispatches a GPU operation to a compute command encoder.
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
/// than 0 in all dimensions. Should be less than or equal to the maximum total threads in group.
/// @param threadgroupsPerGrid Number of thread groups (cells) in the grid of the texture to
/// compute. Must be larger than 0 in all dimensions.
void PNKComputeDispatch(id<MTLComputePipelineState> state,
                        id<MTLCommandBuffer> commandBuffer,
                        NSArray<id<MTLBuffer>> *buffers,
                        NSArray<MPSImage *> *inputImages,
                        NSArray<MPSImage *> *outputImages,
                        NSString * _Nullable commandDescription,
                        MTLSize threadsInGroup,
                        MTLSize threadgroupsPerGrid) API_AVAILABLE(ios(10.0));

/// Dispatches a GPU operation to a compute command encoder.
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
/// than 0 in all dimensions. Should be less than or equal to the maximum total threads in group.
/// @param threadgroupsPerGrid Number of thread groups (cells) in the grid of the texture to
/// compute. Must be larger than 0 in all dimensions.
void PNKComputeDispatch(id<MTLComputePipelineState> state,
                        id<MTLCommandBuffer> commandBuffer,
                        NSArray<id<MTLBuffer>> *buffers,
                        NSString * _Nullable commandDescription,
                        MTLSize threadsInGroup,
                        MTLSize threadgroupsPerGrid);

#endif

NS_ASSUME_NONNULL_END
