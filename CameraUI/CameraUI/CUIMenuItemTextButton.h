// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CUIMenuItemButton.h"

NS_ASSUME_NONNULL_BEGIN

/// \c UIButton that shows text of a \c CUIMenuItemViewModel.
///
/// Ignores the \c iconURL and \c subitems properties of the \c CUIMenuItemViewModel. The text
/// format (e.g. color and font) is being set according to current \c CUISharedTheme instance.
@interface CUIMenuItemTextButton : UIButton <CUIMenuItemButton>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithFrame:(CGRect)aRect NS_UNAVAILABLE;

+ (instancetype)buttonWithType:(UIButtonType)buttonType NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
