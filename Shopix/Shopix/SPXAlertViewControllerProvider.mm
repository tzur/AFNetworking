// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "SPXAlertViewControllerProvider.h"

#import "SPXAlertViewModel.h"
#import "UIAlertController+ViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SPXAlertViewControllerProvider

- (UIViewController *)alertViewControllerWithModel:(id<SPXAlertViewModel>)viewModel {
  return [UIAlertController spx_alertControllerWithViewModel:viewModel];
}

@end

NS_ASSUME_NONNULL_END
