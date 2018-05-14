// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionStaticLayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface PNKImageMotionStaticLayer ()

/// Size of the original image.
@property (nonatomic) cv::Size imageSize;

@end

@implementation PNKImageMotionStaticLayer

- (instancetype)initWithImageSize:(cv::Size)imageSize {
  if (self = [super init]) {
    _imageSize = imageSize;
  }
  return self;
}

- (void)displacements:(cv::Mat *)displacements forTime:(__unused NSTimeInterval)time {
  [self validateDisplacementsMatrix:displacements];
  *displacements = 0;
}

- (void)validateDisplacementsMatrix:(cv::Mat *)displacements {
  LTParameterAssert(displacements->size() == self.imageSize, @"Displacements matrix should be of "
                    "size (%d, %d), got (%d, %d)", self.imageSize.height, self.imageSize.width,
                    displacements->rows, displacements->cols);
  LTParameterAssert(displacements->channels() == 2, @"Displacements matrix should have 2 "
                    "channels, got %d", displacements->channels());
  LTParameterAssert(displacements->depth() == CV_16F, @"Displacements matrix should be of "
                    "half-float type (%d), got %d", CV_16F, displacements->depth());
}

@end

NS_ASSUME_NONNULL_END
