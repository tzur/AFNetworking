// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "WFTestUtils.h"

NS_ASSUME_NONNULL_BEGIN

UIImage *WFCreateBlankImage(CGFloat width, CGFloat height) {
  CGSize size = CGSizeMake(width, height);
  UIGraphicsBeginImageContextWithOptions(size, YES, 0);
  [[UIColor blackColor] setFill];
  UIRectFill(CGRectMake(0, 0, size.width, size.height));
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

NS_ASSUME_NONNULL_END
