// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

NS_ASSUME_NONNULL_BEGIN

/// Class for defining the fonts and colors used in \c CameraUI.
@interface CUITheme : NSObject

- (nullable instancetype)init NS_UNAVAILABLE;

/// Initializes properties with given arguments and no shadow.
- (instancetype)initWithTitleFont:(UIFont *)titleFont
             titleHighlightedFont:(UIFont *)titleHighlightedFont
                       titleColor:(UIColor *)titleColor
            titleHighlightedColor:(UIColor *)titleHighlightedColor
                        iconColor:(UIColor *)iconColor
             iconHighlightedColor:(UIColor *)iconHighlightedColor
              menuBackgroundColor:(UIColor *)menuBackgroundColor;

/// Initializes properties with given arguments.
- (instancetype)initWithTitleFont:(UIFont *)titleFont
             titleHighlightedFont:(UIFont *)titleHighlightedFont
                       titleColor:(UIColor *)titleColor
            titleHighlightedColor:(UIColor *)titleHighlightedColor
                        iconColor:(UIColor *)iconColor
             iconHighlightedColor:(UIColor *)iconHighlightedColor
                iconShadowOpacity:(CGFloat)iconShadowOpacity
                 iconShadowRadius:(CGFloat)iconShadowRadius
                 iconShadowOffset:(CGSize)iconShadowOffset
              menuBackgroundColor:(UIColor *)menuBackgroundColor NS_DESIGNATED_INITIALIZER;

/// Font for title, such as the title of a menu item.
@property (readonly, nonatomic) UIFont *titleFont;

/// Font for selected or highlighted title.
@property (readonly, nonatomic) UIFont *titleHighlightedFont;

/// Color for unselected titles.
@property (readonly, nonatomic) UIColor *titleColor;

/// Color for selected or highlighted titles.
@property (readonly, nonatomic) UIColor *titleHighlightedColor;

/// Color for unselected icons.
@property (readonly, nonatomic) UIColor *iconColor;

/// Color for selected or highlighted icons.
@property (readonly, nonatomic) UIColor *iconHighlightedColor;

/// Icon shadow opacity.
@property (readonly, nonatomic) CGFloat iconShadowOpacity;

/// Icon shadow radius.
@property (readonly, nonatomic) CGFloat iconShadowRadius;

/// Icon shadow offset.
@property (readonly, nonatomic) CGSize iconShadowOffset;

/// Background color for menus.
@property (readonly, nonatomic) UIColor *menuBackgroundColor;

/// Returns the shared theme used by \c CameraUI. If the shared theme was not set, an exception will
/// be raised. Shared theme is set using \c JSObjection for the class \c CUITheme.
+ (CUITheme *)sharedTheme;

@end

NS_ASSUME_NONNULL_END
