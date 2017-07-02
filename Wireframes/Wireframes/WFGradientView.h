// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

NS_ASSUME_NONNULL_BEGIN

/// View that draws a gradient with configurable colors and gradient direction.
@interface WFGradientView : UIView

/// Returns a new \c WFGradientView that displays a horizontal gradient starting with \c leftColor
/// on the left and ending with \c rightColor on the right.
+ (instancetype)horizontalGradientWithLeftColor:(UIColor *)leftColor
                                     rightColor:(UIColor *)rightColor;

/// Returns a new \c WFGradientView that displays a vertical gradient starting with \c topColor on
/// the top and ending with \c bottomColor on the bottom.
+ (instancetype)verticalGradientWithTopColor:(UIColor *)topColor bottomColor:(UIColor *)bottomColor;

/// First element of \c colors, the starting color of the gradient. Defaults to
/// <tt>-[UIColor clearColor]</tt>.
@property (strong, nonatomic) UIColor *startColor;

/// Last element of \c colors, the ending color of the gradient. Defaults to
/// <tt>-[UIColor clearColor]</tt>.
@property (strong, nonatomic) UIColor *endColor;

/// Array of colors of each gradient stop. Must have at least two elements, defaults to
/// <tt>@[[UIColor clearColor], [UIColor clearColor]]</tt>.
@property (copy, nonatomic) NSArray<UIColor *> *colors;

/// The start point of the gradient, defined in a top-left unit coordinate space and mapped to the
/// view's \c bounds. (i.e. [0, 0] is the top-left corner of the view, [1, 1] is the bottom-right
/// corner). The default value is [0, 0.5].
@property (nonatomic) CGPoint startPoint;

/// The end point of the gradient, defined in a top-left unit coordinate space and mapped to the
/// view's \c bounds. (i.e. [0, 0] is the top-left corner of the view, [1, 1] is the bottom-right
/// corner). The default value is [1, 0.5].
@property (nonatomic) CGPoint endPoint;

@end

NS_ASSUME_NONNULL_END
