// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

/// Transparent button with the title "Restore Purchases". Font size is determined by the screen
/// height.
@interface SPXRestorePurchasesButton : UIButton

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

/// Color for the button's text.
@property (strong, nonatomic) UIColor *textColor;

@end

NS_ASSUME_NONNULL_END
