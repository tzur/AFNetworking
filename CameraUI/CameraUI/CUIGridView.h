// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

NS_ASSUME_NONNULL_BEGIN

/// View for displaying a grid. The graphic is comprised of a 3x3 grid. The grid fills \c bounds.
///
/// @note With default values this view is invisible. Set the properties to desired values before
/// displaying.
@interface CUIGridView : UIView

/// Line width used for drawing all lines in the grid graphic.
@property (nonatomic) CGFloat lineWidth;

/// Outline width around all lines in the grid graphic.
@property (nonatomic) CGFloat outlineWidth;

/// Color of all lines in the grid.
@property (strong, nonatomic, nullable) UIColor *color;

/// Color of all outlines in the grid.
@property (strong, nonatomic, nullable) UIColor *outlineColor;

@end

NS_ASSUME_NONNULL_END
