// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

@protocol SPXAlertViewModel;

/// Category that adds helper methods to work with \c SPXAlertViewModel.
@interface UIAlertController (ViewModel)

/// Creates a new \c UIAlertController and applies the given \c viewModel.
///
/// The returned alert controller style is set to \c UIAlertControllerStyleAlert and the style of
/// the alert buttons is set to \c UIAlertActionStyleDefault. All other properties are determined by
/// the given \c viewModel.
+ (instancetype)spx_alertControllerWithViewModel:(id<SPXAlertViewModel>)viewModel;

@end

NS_ASSUME_NONNULL_END
