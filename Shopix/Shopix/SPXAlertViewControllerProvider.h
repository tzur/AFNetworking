// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

@protocol SPXAlertViewModel;

/// Protocol for dynamically creating an alert view controller with a given view model.
///
/// This protocol helps Shopix to present unified but customizable UI by allowing users to provide
/// customized alert views.
@protocol SPXAlertViewControllerProvider <NSObject>

/// Creates a new alert view controller with the given \c viewModel.
- (UIViewController *)alertViewControllerWithModel:(id<SPXAlertViewModel>)viewModel;

@end

/// Default implementation of the \c SPXAlertViewControllerProvider protocol, creates simple
/// \c UIAlertController with the given view model.
@interface SPXAlertViewControllerProvider : NSObject <SPXAlertViewControllerProvider>
@end

NS_ASSUME_NONNULL_END
