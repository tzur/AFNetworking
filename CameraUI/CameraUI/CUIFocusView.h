// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

NS_ASSUME_NONNULL_BEGIN

/// View for displaying a focus graphic on top of the camera. The graphic is comprised of a rounded
/// rectangle with indicators at the centers of the rectangle's edges. The rectangle fills
/// \c bounds.
///
/// @note With default values this view is invisible. Set the properties to desired values before
/// displaying.
@interface CUIFocusView : UIView

/// Length of the indicators.
@property (nonatomic) CGFloat indicatorLength;

/// Radius of the rectangle's rounded corner.
@property (nonatomic) CGFloat cornerRadius;

/// Line width used for drawing all lines in the focus graphic.
@property (nonatomic) CGFloat lineWidth;

/// Color of all lines in the focus graphic.
@property (strong, nonatomic, nullable) UIColor *color;

/// Shadow radius around all lines in the focus graphic.
@property (nonatomic) CGFloat shadowRadius;

/// Color of the shadow.
@property (strong, nonatomic, nullable) UIColor *shadowColor;

/// Opacity of the shadow.
@property (nonatomic) CGFloat shadowOpacity;

@end

NS_ASSUME_NONNULL_END
