// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "UIFont+EnlightUI.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIFont (EnlightUI)

+ (UIFont *)eui_mainLabelFontWithSize:(CGFloat)size {
  return [self systemFontOfSize:size weight:UIFontWeightBold];
}

+ (UIFont *)eui_secondaryLabelFontWithSize:(CGFloat)size {
  return [self systemFontOfSize:size weight:UIFontWeightMedium];
}

+ (UIFont *)eui_mainTextFontWithSize:(CGFloat)size {
  return [self systemFontOfSize:size weight:UIFontWeightRegular];
}

+ (UIFont *)eui_additionalsFontWithSize:(CGFloat)size {
  return [self systemFontOfSize:size weight:UIFontWeightBold];
}

@end

NS_ASSUME_NONNULL_END
