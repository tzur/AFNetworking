// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIMenuItemView.h"

NS_ASSUME_NONNULL_BEGIN

/// \c UIButton that shows text of a \c CUIMenuItemViewModel.
///
/// Ignores the \c iconURL and \c subitems properties of the \c CUIMenuItemViewModel. The text
/// format (e.g. color and font) is being set according to current \c CUISharedTheme instance.
/// \c titleHighlightedFont is used only for \c selected state, and \c titleHighlightedColor is
/// used only for \c highlighted state. When \c enabled is \c NO, the \c alpha of this view is
/// set to \c 0.4.
@interface CUIMenuItemTextButton : UIButton <CUIMenuItemView>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithFrame:(CGRect)aRect NS_UNAVAILABLE;

+ (instancetype)buttonWithType:(UIButtonType)buttonType NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
