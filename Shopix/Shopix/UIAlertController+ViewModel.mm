// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "UIAlertController+ViewModel.h"

#import "SPXAlertViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIAlertController (ViewModel)

+ (instancetype)spx_alertControllerWithViewModel:(id<SPXAlertViewModel>)viewModel {
  auto alertController = [UIAlertController alertControllerWithTitle:viewModel.title
                                                             message:viewModel.message
                                                      preferredStyle:UIAlertControllerStyleAlert];
  [viewModel.buttons
      enumerateObjectsUsingBlock:^(id<SPXAlertButtonViewModel> button, NSUInteger index, BOOL *) {
        auto action = [UIAlertAction actionWithTitle:button.title style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *) {
                                               button.action();
                                             }];
        [alertController addAction:action];
        if (viewModel.defaultButtonIndex &&
            viewModel.defaultButtonIndex.unsignedLongValue == index) {
          alertController.preferredAction = action;
        }
      }];

  return alertController;
}

@end

NS_ASSUME_NONNULL_END
