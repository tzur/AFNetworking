// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

NS_ASSUME_NONNULL_BEGIN

/// View that draws a gradient with configurable colors and gradient direction.
@interface WFGradientView : UIView

/// Returns a new \c WFGradientView that displays a horizontal gradient starting with \c leftColor
/// on the left and ending with \c rightColor on the right. <tt>[UIColor clearColor]</tt> will be
/// used instead of \c nil.
+ (instancetype)horizontalGradientWithLeftColor:(nullable UIColor *)leftColor
                                     rightColor:(nullable UIColor *)rightColor;

/// Returns a new \c WFGradientView that displays a vertical gradient starting with \c topColor on
/// the top and ending with \c bottomColor on the bottom. <tt>[UIColor clearColor]</tt> will be used
/// instead of \c nil.
+ (instancetype)verticalGradientWithTopColor:(nullable UIColor *)topColor
                                 bottomColor:(nullable UIColor *)bottomColor;

/// First element of \c colors, the starting color of the gradient. Defaults to
/// <tt>-[UIColor clearColor]</tt>.
@property (strong, nonatomic, null_resettable) UIColor *startColor;

/// Last element of \c colors, the ending color of the gradient. Defaults to
/// <tt>-[UIColor clearColor]</tt>.
@property (strong, nonatomic, null_resettable) UIColor *endColor;

/// Array of colors of each gradient stop. Must have at least two elements, defaults to
/// <tt>@[[UIColor clearColor], [UIColor clearColor]]</tt>.
@property (copy, nonatomic, null_resettable) NSArray<UIColor *> *colors;

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
