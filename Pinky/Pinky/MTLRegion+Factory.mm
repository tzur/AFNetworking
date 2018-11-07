// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "MTLRegion+Factory.h"

NS_ASSUME_NONNULL_BEGIN

MTLRegion MTLRegionFromCGRect(CGRect rect) {
  return MTLRegionMake2D(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

MTLRegion MTLRegionFromCVRect(cv::Rect rect) {
  return MTLRegionMake2D(rect.x, rect.y, rect.width, rect.height);
}

NS_ASSUME_NONNULL_END
