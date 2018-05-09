// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

#import "CUITheme.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CUITheme

- (nullable instancetype)init {
  /// Prevents JSObjection from initializing instance with default values if it's not bound already.
  return nil;
}

- (instancetype)initWithTitleFont:(UIFont *)titleFont
             titleHighlightedFont:(UIFont *)titleHighlightedFont
                       titleColor:(UIColor *)titleColor
            titleHighlightedColor:(UIColor *)titleHighlightedColor
                        iconColor:(UIColor *)iconColor
             iconHighlightedColor:(UIColor *)iconHighlightedColor
                iconShadowOpacity:(CGFloat)iconShadowOpacity
                 iconShadowRadius:(CGFloat)iconShadowRadius
                 iconShadowOffset:(CGSize)iconShadowOffset
              menuBackgroundColor:(UIColor *)menuBackgroundColor {
  if (self = [super init]) {
    _titleFont = titleFont;
    _titleHighlightedFont = titleHighlightedFont;
    _titleColor = titleColor;
    _titleHighlightedColor = titleHighlightedColor;
    _iconColor = iconColor;
    _iconHighlightedColor = iconHighlightedColor;
    _iconShadowOpacity = iconShadowOpacity;
    _iconShadowRadius = iconShadowRadius;
    _iconShadowOffset = iconShadowOffset;
    _menuBackgroundColor = menuBackgroundColor;
  }
  return self;
}

- (instancetype)initWithTitleFont:(UIFont *)titleFont
             titleHighlightedFont:(UIFont *)titleHighlightedFont
                       titleColor:(UIColor *)titleColor
            titleHighlightedColor:(UIColor *)titleHighlightedColor
                        iconColor:(UIColor *)iconColor
             iconHighlightedColor:(UIColor *)iconHighlightedColor
              menuBackgroundColor:(UIColor *)menuBackgroundColor {
  return [self initWithTitleFont:titleFont titleHighlightedFont:titleHighlightedFont
                      titleColor:titleColor titleHighlightedColor:titleHighlightedColor
                       iconColor:iconColor iconHighlightedColor:iconHighlightedColor
               iconShadowOpacity:0 iconShadowRadius:0 iconShadowOffset:CGSizeZero
             menuBackgroundColor:menuBackgroundColor];
}

+ (CUITheme *)sharedTheme {
  CUITheme *sharedTheme = [JSObjection defaultInjector][[CUITheme class]];
  LTAssert(sharedTheme, @"CUITheme was not set using JSObjection for class CUITheme.");
  return sharedTheme;
}

@end

NS_ASSUME_NONNULL_END
