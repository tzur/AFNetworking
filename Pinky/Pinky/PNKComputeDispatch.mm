// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKComputeDispatch.h"

NS_ASSUME_NONNULL_BEGIN

static inline NSUInteger PNKDivideRoundUp(NSUInteger nominator, NSUInteger denominator) {
  return (nominator + denominator - 1) / denominator;
}

void PNKComputeDispatchWithDefaultThreads(id<MTLComputePipelineState> state,
                                          id<MTLCommandBuffer> commandBuffer,
                                          NSArray<id<MTLBuffer>> *buffers,
                                          NSArray<id<MTLTexture>> *textures,
                                          NSString * _Nullable debugGroup,
                                          MTLSize workingSpaceSize) {
  LTParameterAssert(workingSpaceSize.width > 0 || workingSpaceSize.height > 0 ||
                    workingSpaceSize.depth > 0, @"workingSpaceSize dimensions should be positive. "
                    "got: (%lu, %lu, %lu)", (unsigned long)workingSpaceSize.width,
                    (unsigned long)workingSpaceSize.height, (unsigned long)workingSpaceSize.depth);

  auto width = state.threadExecutionWidth;
  auto height = state.maxTotalThreadsPerThreadgroup / width;
  auto threadsInGroup = MTLSizeMake(width, height, 1);
  auto threadgroupsPerGrid =
      MTLSizeMake(PNKDivideRoundUp(workingSpaceSize.width, threadsInGroup.width),
                  PNKDivideRoundUp(workingSpaceSize.height, threadsInGroup.height),
                  PNKDivideRoundUp(workingSpaceSize.depth, threadsInGroup.depth));
  PNKComputeDispatch(state, commandBuffer, buffers, textures, debugGroup, threadsInGroup,
                     threadgroupsPerGrid);
}

void PNKComputeDispatch(id<MTLComputePipelineState> state, id<MTLCommandBuffer> commandBuffer,
                        NSArray<id<MTLBuffer>> *buffers,
                        NSArray<id<MTLTexture>> *textures,
                        NSString * _Nullable debugGroup,
                        MTLSize threadsInGroup,
                        MTLSize threadgroupsPerGrid) {
  LTParameterAssert(buffers);
  LTParameterAssert(textures);
  LTParameterAssert(threadsInGroup.width > 0 || threadsInGroup.height > 0 ||
                    threadsInGroup.depth > 0, @"threadsInGroup dimensions should be positive. got: "
                    "(%lu, %lu, %lu)", (unsigned long)threadsInGroup.width,
                    (unsigned long)threadsInGroup.height, (unsigned long)threadsInGroup.depth);
  LTParameterAssert(threadgroupsPerGrid.width > 0 || threadgroupsPerGrid.height > 0 ||
                    threadgroupsPerGrid.depth > 0, @"threadgroupsPerGrid dimensions should be "
                    "positive. got: (%lu, %lu, %lu)", (unsigned long)threadgroupsPerGrid.width,
                    (unsigned long)threadgroupsPerGrid.height,
                    (unsigned long)threadgroupsPerGrid.depth);

  auto encoder = [commandBuffer computeCommandEncoder];
  if (debugGroup) {
    [encoder pushDebugGroup:debugGroup];
  }

  [buffers enumerateObjectsUsingBlock:^(id<MTLBuffer> buffer, NSUInteger index, BOOL *) {
    [encoder setBuffer:buffer offset:0 atIndex:index];
  }];
  [textures enumerateObjectsUsingBlock:^(id<MTLTexture> texture, NSUInteger index, BOOL *) {
    [encoder setTexture:texture atIndex:index];
  }];
  [encoder setComputePipelineState:state];
  [encoder dispatchThreadgroups:threadgroupsPerGrid threadsPerThreadgroup:threadsInGroup];

  if (debugGroup) {
    [encoder popDebugGroup];
  }
  [encoder endEncoding];
}

NS_ASSUME_NONNULL_END
