// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

NS_ASSUME_NONNULL_BEGIN

/// View that shows a pressable circular button. The button's graphic is comprised of a ring and
/// within it another oval. Both the ring and the oval are centered within \c bounds. This button
/// resembles the iPhone's camera 'shoot' button (iOS 9).
///
/// @note With default values this view is invisible. Set the properties to the desired values
/// before displaying.
@interface CUIOvalButton : UIControl

/// Size of the bounding box of the ring.
@property (nonatomic) CGSize ringSize;

/// Difference between the ring's outer radius and inner radius.
@property (nonatomic) CGFloat ringWidth;

/// Size of the bounding box of the oval.
@property (nonatomic) CGSize ovalSize;

/// Color of all parts of the graphic.
@property (strong, nonatomic, nullable) UIColor *color;

/// Alpha used for the button when it is disabled.
@property (nonatomic) CGFloat disabledAlpha;

/// Color used for the oval when the button is highlighted.
@property (strong, nonatomic, nullable) UIColor *highlightColor;

@end

NS_ASSUME_NONNULL_END
