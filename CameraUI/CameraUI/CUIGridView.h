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

/// Color of all lines in the grid.
@property (strong, nonatomic, nullable) UIColor *color;

/// Shadow radius around all lines in the grid graphic.
@property (nonatomic) CGFloat shadowRadius;

/// Color of the shadow.
@property (strong, nonatomic, nullable) UIColor *shadowColor;

/// Opacity of the shadow.
@property (nonatomic) CGFloat shadowOpacity;

@end

/// Category for creating \c CUIGridView instances with commonly used settings.
@interface CUIGridView (Factory)

/// Returns a white grid with 25% transparent black shadow.
+ (CUIGridView *)whiteGrid;

@end

NS_ASSUME_NONNULL_END
