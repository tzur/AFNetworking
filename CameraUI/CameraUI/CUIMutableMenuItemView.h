// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

@protocol CUIMenuItemViewModel;

NS_ASSUME_NONNULL_BEGIN

/// Protocol for showing a \c CUIMenuItemViewModel, where the \c viewModel can be changed.
@protocol CUIMutableMenuItemView <NSObject>

/// View model to determine the properties displayed by this view.
@property (strong, nonatomic) id<CUIMenuItemViewModel> viewModel;

@end

NS_ASSUME_NONNULL_END
