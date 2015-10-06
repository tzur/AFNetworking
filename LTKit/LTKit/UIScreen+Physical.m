// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "UIScreen+Physical.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIScreen (Physical)

- (CGFloat)lt_pointsPerInchForPixelsPerInch:(CGFloat)pixelsPerInch {
  return pixelsPerInch / self.nativeScale;
}

@end

NS_ASSUME_NONNULL_END
