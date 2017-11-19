// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

/// View contains horizontally aligned buttons, where one of the buttons can be enlarged.
@interface SPXButtonsHorizontalLayoutView : UIView

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

/// Buttons that will be centered and horizontally aligned from left to right. Reset the buttons
/// will also set \c enlargedButtonIndex to \c nil.
@property (strong, nonatomic) NSArray<UIButton *> *buttons;

/// Index of a button that will be enlarged, must be in range <tt>[0, buttons.count - 1]</tt>,
/// otherwise a \c NSInvalidArgumentException is raised. If set to \c nil none of the buttons will
/// be enlarged.
@property (strong, nonatomic, nullable) NSNumber *enlargedButtonIndex;

/// Hot signal that sends the button's index when a button is pressed.
@property (readonly, nonatomic) RACSignal<NSNumber *> *buttonPressed;

/// Button width ratio over its height. Defaults to \c 1.0.
@property (nonatomic) CGFloat buttonAspectRatio;

/// Spacing between the buttons ratio over the enlarged button height or over the original button
/// height if there is no enlarged button. Defaults to \c 0.058.
@property (nonatomic) CGFloat spacingRatio;

@end

NS_ASSUME_NONNULL_END
