// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXColorScheme.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SPXColorScheme

- (instancetype)initWithMainColor:(UIColor *)mainColor
                        textColor:(UIColor *)textColor
                    darkTextColor:(UIColor *)darkTextColor
                  greyedTextColor:(UIColor *)greyedTextColor
                  backgroundColor:(UIColor *)backgroundColor {
  if (self = [super init]) {
    _mainColor = mainColor;
    _textColor = textColor;
    _darkTextColor = darkTextColor;
    _greyedTextColor = greyedTextColor;
    _backgroundColor = backgroundColor;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
