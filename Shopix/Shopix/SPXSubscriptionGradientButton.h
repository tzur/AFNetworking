// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

/// Default implementation of a rounded corners button with two vertically aligned labels where the
/// bottom label has a linear gradient background and is highlighted on press.
@interface SPXSubscriptionGradientButton : UIButton

/// Top text.
@property (strong, nonatomic, nullable) NSAttributedString *topText;

/// Bottom text.
@property (strong, nonatomic, nullable) NSAttributedString *bottomText;

/// Top label background color. Defaults to <tt>[UIColor whiteColor]</tt>.
@property (strong, nonatomic, nullable) UIColor *topBackgroundColor;

/// Bottom background horizontal gradient colors. Must have at least two elements, defaults to
/// <tt>@[[UIColor clearColor], [UIColor clearColor]]</tt>.
@property (copy, nonatomic) NSArray<UIColor *> *bottomGradientColors;

/// Button's border color, \c nil if there is no border. If this property is not \c nil border width
/// is set to \c 3, otherwise it is set to \c 0.
@property (nonatomic, nullable) UIColor *borderColor;

@end

NS_ASSUME_NONNULL_END
