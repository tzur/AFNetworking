// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

#import "CUITheme.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CUITheme

- (instancetype)init {
  /// Prevents JSObjection from initializing instance with default values if it's not bound already.
  return nil;
}

- (instancetype)initWithTitleFont:(UIFont *)titleFont
             titleHighlightedFont:(UIFont *)titleHighlightedFont
                       titleColor:(UIColor *)titleColor
            titleHighlightedColor:(UIColor *)titleHighlightedColor
                        iconColor:(UIColor *)iconColor
             iconHighlightedColor:(UIColor *)iconHighlightedColor
              menuBackgroundColor:(UIColor *)menuBackgroundColor {
  if (self = [super init]) {
    _titleFont = titleFont;
    _titleHighlightedFont = titleHighlightedFont;
    _titleColor = titleColor;
    _titleHighlightedColor = titleHighlightedColor;
    _iconColor = iconColor;
    _iconHighlightedColor = iconHighlightedColor;
    _menuBackgroundColor = menuBackgroundColor;
  }
  return self;
}

+ (CUITheme *)sharedTheme {
  CUITheme *sharedTheme = [JSObjection defaultInjector][[CUITheme class]];
  LTAssert(sharedTheme, @"CUITheme was not set using JSObjection for class CUITheme.");
  return sharedTheme;
}

@end

NS_ASSUME_NONNULL_END
