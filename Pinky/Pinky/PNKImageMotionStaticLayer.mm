// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionStaticLayer.h"

#import "PNKImageMotionLayerUtils.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PNKImageMotionStaticLayer

@synthesize imageSize = _imageSize;

- (instancetype)initWithImageSize:(cv::Size)imageSize {
  if (self = [super init]) {
    _imageSize = imageSize;
  }
  return self;
}

- (void)displacements:(cv::Mat *)displacements forTime:(__unused NSTimeInterval)time {
  PNKImageMotionValidateDisplacementsMatrix(*displacements, self.imageSize);
  *displacements = 0;
}

@end

NS_ASSUME_NONNULL_END
