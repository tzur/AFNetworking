// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "UIColor+EnlightUI.h"

#import <LTKit/UIColor+Utilities.h>

NS_ASSUME_NONNULL_BEGIN

@implementation UIColor (EnlightUI)

+ (UIColor *)eui_mainDarkColor {
  return [UIColor lt_colorWithHex:@"#131314"];
}

+ (UIColor *)eui_secondaryDarkColor {
  return [UIColor lt_colorWithHex:@"#202023"];
}

+ (UIColor *)eui_mainTextColor {
  return [UIColor lt_colorWithHex:@"#F7F7F7"];
}

+ (UIColor *)eui_secondaryTextColor {
  return [UIColor lt_colorWithHex:@"#7D7A83"];
}

+ (UIColor *)eui_whiteColor {
  return [UIColor lt_colorWithHex:@"#FFFFFF"];
}

@end

NS_ASSUME_NONNULL_END
