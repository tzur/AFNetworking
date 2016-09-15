// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for defining the fonts and colors used in \c CameraUI.
@protocol CUITheme <NSObject>

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

/// Background color for menus.
@property (readonly, nonatomic) UIColor *menuBackgroundColor;

@end

/// Class for getting the shared theme used by \c CameraUI, shared theme is set using \c JSObjection
/// for the protocol \c CUITheme.
@interface CUISharedTheme : NSObject

/// Returns the shared theme used by \c CameraUI. If the shared theme was not set, an exception will
/// be raised.
+ (id<CUITheme>)sharedTheme;

@end

NS_ASSUME_NONNULL_END
