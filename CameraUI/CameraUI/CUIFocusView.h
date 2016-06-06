// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

NS_ASSUME_NONNULL_BEGIN

/// View for displaying a focus graphic on top of the camera. The graphic is comprised of a
/// rectangle with a plus sign in its center. The rectangle fills \c bounds, while the plus's size
/// is controlled via \c plusLength.
///
/// @note With default values this view is invisible. Set the properties to desired values before
/// displaying.
@interface CUIFocusView : UIView

/// Length of the plus icon.
@property (nonatomic) CGFloat plusLength;

/// Line width used for drawing all lines in the focus graphic.
@property (nonatomic) CGFloat lineWidth;

/// Outline width around all lines in the focus graphic.
@property (nonatomic) CGFloat outlineWidth;

/// Color of all lines in the focus graphic.
@property (strong, nonatomic, nullable) UIColor *color;

/// Color of all outlines in the focus graphic.
@property (strong, nonatomic, nullable) UIColor *outlineColor;

@end

NS_ASSUME_NONNULL_END
