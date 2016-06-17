// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTHorizontalPackingRectsProvider.h"

@implementation LTHorizontalPackingRectsProvider

- (lt::unordered_map<NSString *, CGRect>)packingOfSizes:
    (const lt::unordered_map<NSString *, CGSize> &)sizes {
  CGFloat widthsSum = 0;

  lt::unordered_map<NSString *, CGRect> areas;
  for (const auto &keyValue : sizes) {
    NSString *key = keyValue.first;
    CGSize size = keyValue.second;
    LTParameterAssert(size.width > 0 && size.height > 0, @"sizes cannot have non-positive values "
                      "but size at key %@ is %@", key, NSStringFromCGSize(size));
    CGRect area = CGRectMake(widthsSum, 0, size.width, size.height);
    areas[key] = area;

    widthsSum += size.width;
  }

  return areas;
}

@end
