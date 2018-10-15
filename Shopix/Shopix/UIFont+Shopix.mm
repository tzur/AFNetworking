// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "UIFont+Shopix.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIFont (Shopix)

+ (UIFont *)spx_fontWithSizeRatio:(CGFloat)ratio minSize:(NSUInteger)minSize
                          maxSize:(NSUInteger)maxSize weight:(UIFontWeight)weight {
  auto windowHeight = [UIApplication sharedApplication].keyWindow.bounds.size.height;
  return [UIFont systemFontOfSize:std::clamp<CGFloat>(ratio * windowHeight, minSize, maxSize)
                           weight:weight];
}

+ (UIFont *)spx_standardFontWithSizeRatio:(CGFloat)ratio minSize:(NSUInteger)minSize
                                  maxSize:(NSUInteger)maxSize {
  return [UIFont spx_fontWithSizeRatio:ratio minSize:minSize maxSize:maxSize
                                weight:UIFontWeightRegular];
}

@end

NS_ASSUME_NONNULL_END
