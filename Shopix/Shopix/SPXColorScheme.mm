// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXColorScheme.h"

#import <LTKit/UIColor+Utilities.h>

NS_ASSUME_NONNULL_BEGIN

@implementation SPXColorScheme

- (instancetype)initWithMainColor:(UIColor *)mainColor
                        textColor:(UIColor *)textColor
                    darkTextColor:(UIColor *)darkTextColor
                  grayedTextColor:(UIColor *)grayedTextColor
                  backgroundColor:(UIColor *)backgroundColor {

  if (self = [super init]) {
    _mainColor = mainColor;
    _textColor = textColor;
    _darkTextColor = darkTextColor;
    _grayedTextColor = grayedTextColor;
    _backgroundColor = backgroundColor;
    _mainGradientColors = @[
      mainColor,
      mainColor
    ];
    _multiAppGradientColors = self.mainGradientColors;
  }
  return self;
}

- (void)setMainGradientColors:(NSArray<UIColor *> *)mainGradientColors {
  LTParameterAssert(mainGradientColors.count > 1, @"Invalid gradient colors array, must have at "
                    "least 2 colors, got %lu", (unsigned long)mainGradientColors.count);
  _mainGradientColors = [mainGradientColors copy];
}

- (void)setMultiAppGradientColors:(NSArray<UIColor *> *)multiAppGradientColors {
  LTParameterAssert(multiAppGradientColors.count > 1, @"Invalid gradient colors array, must "
                    "have at least 2 colors, got %lu",
                    (unsigned long)multiAppGradientColors.count);
  _multiAppGradientColors = [multiAppGradientColors copy];
}

@end

NS_ASSUME_NONNULL_END
