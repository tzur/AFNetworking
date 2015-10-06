// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTSplitComplexMat.h"

@interface LTSplitComplexMat () {
  cv::Mat1f _real;
  cv::Mat1f _imag;
}
@end

@implementation LTSplitComplexMat

- (instancetype)init {
  return [self initWithReal:cv::Mat1f() imag:cv::Mat1f()];
}

- (instancetype)initWithReal:(const cv::Mat1f &)real imag:(const cv::Mat1f &)imag {
  if (self = [super init]) {
    _real = real;
    _imag = imag;
  }
  return self;
}

@end
