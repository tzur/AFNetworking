// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIMenuItemView.h"

NS_ASSUME_NONNULL_BEGIN

/// \c UIButton that shows an icon of a \c CUIMenuItemViewModel.
///
/// Ignores the \c title and \c subitems properties of the \c CUIMenuItemViewModel.
///
/// The icon's color, highlighted color and selected color are being set according to current \c
/// CUISharedTheme instance.
@interface CUIMenuItemIconButton : UIButton <CUIMenuItemView>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithFrame:(CGRect)aRect NS_UNAVAILABLE;

+ (instancetype)buttonWithType:(UIButtonType)buttonType NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
