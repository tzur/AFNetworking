// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "UIImage+Factory.h"

#import "LTImage.h"
#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIImage (Factory)

+ (UIImage *)lt_imageWithTexture:(LTTexture *)texture {
  __block UIImage *image;

  [texture mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
    image = [self lt_imageWithMat:mapped];
  }];

  return image;
}

+ (UIImage *)lt_imageWithMat:(const cv::Mat &)mat {
  return [[LTImage alloc] initWithMat:mat copy:NO].UIImage;
}

@end

NS_ASSUME_NONNULL_END
