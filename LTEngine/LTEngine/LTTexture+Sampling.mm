// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTexture+Sampling.h"

@implementation LTTexture (Sampling)

- (void)beginSamplingWithGPU {
  LTMethodNotImplemented();
}

- (void)endSamplingWithGPU {
  LTMethodNotImplemented();
}

- (void)sampleWithGPUWithBlock:(LTVoidBlock)block {
  LTParameterAssert(block);
  [self beginSamplingWithGPU];
  block();
  [self endSamplingWithGPU];
}

@end
