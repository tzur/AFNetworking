// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "MTBComputeDispatch.h"

#import <LTKit/NSArray+Functional.h>

NS_ASSUME_NONNULL_BEGIN

static inline NSUInteger MTBDivideRoundUp(NSUInteger nominator, NSUInteger denominator) {
  return (nominator + denominator - 1) / denominator;
}

static void MTBComputeDispatchInternal(id<MTLComputePipelineState> state,
                                       id<MTLCommandBuffer> commandBuffer,
                                       NSArray<id<MTLBuffer>> *buffers,
                                       NSArray<id<MTLTexture>> *textures,
                                       NSString * _Nullable commandDescription,
                                       MTLSize threadsInGroup,
                                       MTLSize threadGroupsPerGrid) {
  LTParameterAssert(threadsInGroup.width > 0 || threadsInGroup.height > 0 ||
                    threadsInGroup.depth > 0, @"threadsInGroup dimensions should be positive. got: "
                    "(%lu, %lu, %lu)", (unsigned long)threadsInGroup.width,
                    (unsigned long)threadsInGroup.height, (unsigned long)threadsInGroup.depth);
  LTParameterAssert(threadsInGroup.width * threadsInGroup.height * threadsInGroup.depth <=
                    state.maxTotalThreadsPerThreadgroup, @"total thread count in group must be "
                    "less than or equal to %lu. got: %lu * %lu * %lu = %lu",
                    (unsigned long)state.maxTotalThreadsPerThreadgroup,
                    (unsigned long)threadsInGroup.width,
                    (unsigned long)threadsInGroup.height, (unsigned long)threadsInGroup.depth,
                    (unsigned long)(threadsInGroup.width * threadsInGroup.height *
                                    threadsInGroup.depth));
  LTParameterAssert(threadGroupsPerGrid.width > 0 || threadGroupsPerGrid.height > 0 ||
                    threadGroupsPerGrid.depth > 0, @"threadgroupsPerGrid dimensions should be "
                    "positive. got: (%lu, %lu, %lu)", (unsigned long)threadGroupsPerGrid.width,
                    (unsigned long)threadGroupsPerGrid.height,
                    (unsigned long)threadGroupsPerGrid.depth);

  auto encoder = [commandBuffer computeCommandEncoder];
  if (commandDescription) {
    [encoder pushDebugGroup:nn(commandDescription)];
  }

  [buffers enumerateObjectsUsingBlock:^(id<MTLBuffer> buffer, NSUInteger index, BOOL *) {
    [encoder setBuffer:buffer offset:0 atIndex:index];
  }];
  [textures enumerateObjectsUsingBlock:^(id<MTLTexture> texture, NSUInteger index, BOOL *) {
    [encoder setTexture:texture atIndex:index];
  }];
  [encoder setComputePipelineState:state];
  [encoder dispatchThreadgroups:threadGroupsPerGrid threadsPerThreadgroup:threadsInGroup];

  if (commandDescription) {
    [encoder popDebugGroup];
  }
  [encoder endEncoding];
}

void MTBComputeDispatchWithDefaultThreads(id<MTLComputePipelineState> state,
                                          id<MTLCommandBuffer> commandBuffer,
                                          NSArray<id<MTLBuffer>> *buffers,
                                          NSArray<MPSImage *> *inputImages,
                                          NSArray<MPSImage *> *outputImages,
                                          NSString * _Nullable commandDescription,
                                          MTLSize workingSpaceSize) {
  auto width = state.threadExecutionWidth;
  auto height = state.maxTotalThreadsPerThreadgroup / width;
  auto threadsInGroup = MTLSizeMake(width, height, 1);
  MTLSize threadGroupsPerGrid = {
    MTBDivideRoundUp(workingSpaceSize.width, threadsInGroup.width),
    MTBDivideRoundUp(workingSpaceSize.height, threadsInGroup.height),
    MTBDivideRoundUp(workingSpaceSize.depth, threadsInGroup.depth)
  };

  MTBComputeDispatch(state, commandBuffer, buffers, inputImages, outputImages, commandDescription,
                     threadsInGroup, threadGroupsPerGrid);
}

void MTBComputeDispatchWithDefaultThreads(id<MTLComputePipelineState> state,
                                          id<MTLCommandBuffer> commandBuffer,
                                          NSArray<id<MTLBuffer>> *buffers,
                                          NSString * _Nullable commandDescription,
                                          NSUInteger workingBufferSize) {
  LTParameterAssert(workingBufferSize > 0 , @"workingBufferSize should be positive. got: %lu",
                    (unsigned long)workingBufferSize);

  auto threadsInGroup = MTLSizeMake(state.maxTotalThreadsPerThreadgroup, 1, 1);
  auto threadgroupsPerGrid =
      MTLSizeMake(MTBDivideRoundUp(workingBufferSize, threadsInGroup.width), 1, 1);
  MTBComputeDispatch(state, commandBuffer, buffers, commandDescription, threadsInGroup,
                     threadgroupsPerGrid);
}

void MTBComputeDispatchWithDefaultThreads(id<MTLComputePipelineState> state,
                                          id<MTLCommandBuffer> commandBuffer,
                                          NSArray<MPSImage *> *inputImages,
                                          NSArray<MPSImage *> *outputImages,
                                          NSString * _Nullable commandDescription,
                                          MTLSize workingSpaceSize) {
  MTBComputeDispatchWithDefaultThreads(state, commandBuffer, @[], inputImages, outputImages,
                                       commandDescription, workingSpaceSize);
}

void MTBComputeDispatch(id<MTLComputePipelineState> state,
                        id<MTLCommandBuffer> commandBuffer,
                        NSArray<id<MTLBuffer>> *buffers,
                        NSArray<MPSImage *> *inputImages,
                        NSArray<MPSImage *> *outputImages,
                        NSString * _Nullable commandDescription,
                        MTLSize threadsInGroup,
                        MTLSize threadGroupsPerGrid) {
  NSArray<id<MTLTexture>> *inputTextures = [inputImages lt_map:^id(MPSImage *inputImage) {
    return inputImage.texture;
  }];
  NSArray<id<MTLTexture>> *outputTextures = [outputImages lt_map:^id(MPSImage *outputImage) {
    return outputImage.texture;
  }];

  NSArray<id<MTLTexture>> *textures = [inputTextures arrayByAddingObjectsFromArray:outputTextures];

  MTBComputeDispatchInternal(state, commandBuffer, buffers, textures, commandDescription,
                             threadsInGroup, threadGroupsPerGrid);

  for (MPSImage *inputImage in inputImages) {
    if ([inputImage isKindOfClass:[MPSTemporaryImage class]]) {
      ((MPSTemporaryImage *)inputImage).readCount -= 1;
    }
  }
}

void MTBComputeDispatch(id<MTLComputePipelineState> state,
                        id<MTLCommandBuffer> commandBuffer,
                        NSArray<id<MTLBuffer>> *buffers,
                        NSString * _Nullable commandDescription,
                        MTLSize threadsInGroup,
                        MTLSize threadgroupsPerGrid) {
  MTBComputeDispatch(state, commandBuffer, buffers, @[], @[], commandDescription, threadsInGroup,
                     threadgroupsPerGrid);
}

void MTBComputeDispatch(id<MTLComputePipelineState> state, id<MTLCommandBuffer> commandBuffer,
                        NSArray<MPSImage *> *inputImages, NSArray<MPSImage *> *outputImages,
                        NSString * _Nullable commandDescription, MTLSize threadsInGroup,
                        MTLSize threadgroupsPerGrid) {
  MTBComputeDispatch(state, commandBuffer, @[], inputImages, outputImages, commandDescription,
                     threadsInGroup, threadgroupsPerGrid);
}

NS_ASSUME_NONNULL_END
