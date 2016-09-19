// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "WFTestUtils.h"

#import <LTKit/LTCGExtensions.h>

NS_ASSUME_NONNULL_BEGIN

UIImage *WFCreateBlankImage(CGFloat width, CGFloat height) {
  return WFCreateSolidImage(width, height, [UIColor blackColor]);
}

UIImage *WFCreateSolidImage(CGFloat width, CGFloat height, UIColor *color) {
  CGSize size = CGSizeMake(width, height);
  UIGraphicsBeginImageContextWithOptions(size, NO, 0);
  [color setFill];
  UIRectFill(CGRectMake(0, 0, size.width, size.height));
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

UIColor *WFGetPixelColor(UIImage *image, CGFloat x, CGFloat y) {
  LTParameterAssert(x >= 0 && x < image.size.width, @"x coordinate (%g) is out of bounds for "
                    "(%g, %g) image", x, image.size.width, image.size.height);
  LTParameterAssert(y >= 0 && y < image.size.height, @"y coordinate (%g) is out of bounds for "
                    "(%g, %g) image", y, image.size.width, image.size.height);

  UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), NO, 1);

  CGContextRef ctx = UIGraphicsGetCurrentContext();
  CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);

  CGFloat imageWidth = image.size.width * image.scale;
  CGFloat imageHeight = image.size.height * image.scale;
  [image drawInRect:CGRectMake(-(x * image.scale), -(y * image.scale), imageWidth, imageHeight)
          blendMode:kCGBlendModeCopy alpha:1];

  uint8_t *data = (uint8_t *)CGBitmapContextGetData(ctx);
  UIColor *color = [UIColor colorWithRed:data[2] / 255.0f
                                   green:data[1] / 255.0f
                                    blue:data[0] / 255.0f
                                   alpha:data[3] / 255.0f];
  UIGraphicsEndImageContext();

  return color;
}

UIImage *WFTakeViewSnapshot(UIView *view) {
  UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, view.contentScaleFactor);
  [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
  UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return snapshot;
}

NS_ASSUME_NONNULL_END
