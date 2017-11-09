// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

/// View presenting two labels aligned vertically on top of each other.
@interface SPXDualLabelView : UIView

/// Ratio of the top label height over the bottom label height. Defaults to \c 0.56.
@property (nonatomic) CGFloat lablesRatio;

/// Top text. Defaults to \c nil.
@property (strong, nonatomic, nullable) NSAttributedString *topText;

/// Bottom text. Defaults to \c nil.
@property (strong, nonatomic, nullable) NSAttributedString *bottomText;

/// Top label background color. Defaults to \c nil.
@property (strong, nonatomic, nullable) UIColor *topBackgroundColor;

/// Bottom label background color. Defaults to \c nil.
@property (strong, nonatomic, nullable) UIColor *bottomBackgroundColor;

@end

NS_ASSUME_NONNULL_END
