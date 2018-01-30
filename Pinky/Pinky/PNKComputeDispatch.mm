// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKComputeDispatch.h"

#import <LTKit/NSArray+Functional.h>

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

static inline NSUInteger PNKDivideRoundUp(NSUInteger nominator, NSUInteger denominator) {
  return (nominator + denominator - 1) / denominator;
}

static void PNKComputeDispatchInternal(id<MTLComputePipelineState> state,
                                       id<MTLCommandBuffer> commandBuffer,
                                       NSArray<id<MTLBuffer>> *buffers,
                                       NSArray<id<MTLTexture>> *textures,
                                       NSString * _Nullable commandDescription,
                                       MTLSize threadsInGroup,
                                       MTLSize threadGroupsPerGrid) {
  LTParameterAssert(buffers);
  LTParameterAssert(textures);
  LTParameterAssert(threadsInGroup.width > 0 || threadsInGroup.height > 0 ||
                    threadsInGroup.depth > 0, @"threadsInGroup dimensions should be positive. got: "
                    "(%lu, %lu, %lu)", (unsigned long)threadsInGroup.width,
                    (unsigned long)threadsInGroup.height, (unsigned long)threadsInGroup.depth);
  LTParameterAssert(threadGroupsPerGrid.width > 0 || threadGroupsPerGrid.height > 0 ||
                    threadGroupsPerGrid.depth > 0, @"threadgroupsPerGrid dimensions should be "
                    "positive. got: (%lu, %lu, %lu)", (unsigned long)threadGroupsPerGrid.width,
                    (unsigned long)threadGroupsPerGrid.height,
                    (unsigned long)threadGroupsPerGrid.depth);

  auto encoder = [commandBuffer computeCommandEncoder];
  if (commandDescription) {
    [encoder pushDebugGroup:commandDescription];
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

void PNKComputeDispatchWithDefaultThreads(id<MTLComputePipelineState> state,
                                          id<MTLCommandBuffer> commandBuffer,
                                          NSArray<id<MTLBuffer>> *buffers,
                                          NSString * _Nullable commandDescription,
                                          NSUInteger workingBufferSize) {
  LTParameterAssert(workingBufferSize > 0 , @"workingBufferSize should be positive. got: %lu",
                    (unsigned long)workingBufferSize);

  auto threadsInGroup = MTLSizeMake(state.maxTotalThreadsPerThreadgroup, 1, 1);
  auto threadgroupsPerGrid =
      MTLSizeMake(PNKDivideRoundUp(workingBufferSize, threadsInGroup.width), 1, 1);
  PNKComputeDispatch(state, commandBuffer, buffers, commandDescription, threadsInGroup,
                     threadgroupsPerGrid);
}

void PNKComputeDispatch(id<MTLComputePipelineState> state,
                        id<MTLCommandBuffer> commandBuffer,
                        NSArray<id<MTLBuffer>> *buffers,
                        NSString * _Nullable commandDescription,
                        MTLSize threadsInGroup,
                        MTLSize threadgroupsPerGrid) {
  PNKComputeDispatchInternal(state, commandBuffer, buffers, @[], commandDescription, threadsInGroup,
                             threadgroupsPerGrid);
}

void PNKComputeDispatchWithDefaultThreads(id<MTLComputePipelineState> state,
                                          id<MTLCommandBuffer> commandBuffer,
                                          NSArray<MPSImage *> *inputImages,
                                          NSArray<MPSImage *> *outputImages,
                                          NSString * _Nullable commandDescription,
                                          MTLSize workingSpaceSize) {
  PNKComputeDispatchWithDefaultThreads(state, commandBuffer, @[], inputImages, outputImages,
                                       commandDescription, workingSpaceSize);
}

void PNKComputeDispatchWithDefaultThreads(id<MTLComputePipelineState> state,
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
    PNKDivideRoundUp(workingSpaceSize.width, threadsInGroup.width),
    PNKDivideRoundUp(workingSpaceSize.height, threadsInGroup.height),
    PNKDivideRoundUp(workingSpaceSize.depth, threadsInGroup.depth)
  };

  PNKComputeDispatch(state, commandBuffer, buffers, inputImages, outputImages, commandDescription,
                     threadsInGroup, threadGroupsPerGrid);
}

void PNKComputeDispatch(id<MTLComputePipelineState> state,
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

  PNKComputeDispatchInternal(state, commandBuffer, buffers, textures, commandDescription,
                             threadsInGroup, threadGroupsPerGrid);

  for (MPSImage *inputImage in inputImages) {
    if ([inputImage isKindOfClass:[MPSTemporaryImage class]]) {
      ((MPSTemporaryImage *)inputImage).readCount -= 1;
    }
  }
}

#endif

NS_ASSUME_NONNULL_END
