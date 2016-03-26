// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

/// Category on \c LTTexture that enables proper synchronization between GPU-based sampling and
/// CPU-based read-write.
@interface LTTexture (Sampling)

#pragma mark -
#pragma mark Abstract methods
#pragma mark -

/// Marks the beginning of a GPU sampling operation from the texture.
///
/// @note for automatic scoping, prefer calls to \c readFromTexture: instead of calling
/// \c beginSamplingWithGPU and \c endSamplingWithGPU.
///
/// @see \c sampleWithGPUWithBlock: for more information.
- (void)beginSamplingWithGPU;

/// Marks the end of a GPU sampling operation from the texture.
///
/// @note for automatic scoping, prefer calls to \c readFromTexture: instead of calling
/// \c beginSamplingWithGPU and \c endSamplingWithGPU.
///
/// @see \c sampleWithGPUWithBlock: for more information.
- (void)endSamplingWithGPU;

#pragma mark -
#pragma mark Implemented methods
#pragma mark -

/// Executes the block which is marked as a block that samples from the texture using the GPU,
/// allowing the texture to synchronize before and after the sampling.
///
/// @note all texture samplings that are GPU based should be executed via this method, or be wrapped
/// with \c beginSamplingWithGPU and \c endSamplingWithGPU calls.
- (void)sampleWithGPUWithBlock:(LTVoidBlock)block;

@end

NS_ASSUME_NONNULL_END
