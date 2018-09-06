// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKFillWithZeroesKernel.h"

#import "PNKTestComputeState.h"

NS_ASSUME_NONNULL_BEGIN

@interface PNKFillWithZeroesKernel ()

/// Device to encode this kernel operation.
@property (readonly, nonatomic) id<MTLDevice> device;

/// Kernel state to encode operation on a single texture.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateSingle;

/// Kernel state to encode operation on a texture array.
@property (readonly, nonatomic) id<MTLComputePipelineState> stateArray;

@end

@implementation PNKFillWithZeroesKernel

/// Name of kernel function for performing operation on a single texture.
static NSString * const kKernelFunctionSingle = @"fillWithZeroesSingle";

/// Name of kernel function for performing operation on a texture array.
static NSString * const kKernelFunctionArray = @"fillWithZeroesArray";

/// Family name of the kernel functions for debug purposes.
static NSString * const kDebugGroupName = @"fillWithZeroes";

- (instancetype)initWithDevice:(id<MTLDevice>)device {
  if (self = [super init]) {
    _device = device;
    [self createStates];
  }
  return self;
}

- (void)createStates {
  _stateSingle = PNKCreateTestComputeState(self.device, kKernelFunctionSingle);
  _stateArray = PNKCreateTestComputeState(self.device, kKernelFunctionArray);
}

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                  outputImage:(MPSImage *)outputImage {
  MTLSize workingSpaceSize = outputImage.pnk_textureArraySize;

  bool isSingle = outputImage.pnk_isSingleTexture;
  auto state = isSingle ? self.stateSingle : self.stateArray;

  MTBComputeDispatchWithDefaultThreads(state, commandBuffer, @[], @[outputImage], kDebugGroupName,
                                       workingSpaceSize);
}

@end

NS_ASSUME_NONNULL_END
