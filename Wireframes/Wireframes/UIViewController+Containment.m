// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "UIViewController+Containment.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIViewController (Containment)

- (void)wf_addChildViewController:(UIViewController *)viewController {
  [self wf_addChildViewController:viewController toView:self.view];
}

- (void)wf_insertChildViewController:(UIViewController *)viewController
                        belowSubview:(UIView *)subview {
  [self wf_insertChildViewController:viewController toView:self.view belowSubview:subview];
}

- (void)wf_insertChildViewController:(UIViewController *)viewController
                        aboveSubview:(UIView *)subview {
  [self wf_insertChildViewController:viewController toView:self.view aboveSubview:subview];
}

- (void)wf_addChildViewController:(UIViewController *)viewController toView:(UIView *)view {
  [self addChildViewController:viewController];
  [view addSubview:viewController.view];
  [viewController didMoveToParentViewController:self];
}

- (void)wf_insertChildViewController:(UIViewController *)viewController toView:(UIView *)view
                        belowSubview:(UIView *)subview {
  [self addChildViewController:viewController];
  [view insertSubview:viewController.view belowSubview:subview];
  [viewController didMoveToParentViewController:self];
}

- (void)wf_insertChildViewController:(UIViewController *)viewController toView:(UIView *)view
                        aboveSubview:(UIView *)subview {
  [self addChildViewController:viewController];
  [view insertSubview:viewController.view aboveSubview:subview];
  [viewController didMoveToParentViewController:self];
}

- (void)wf_removeChildViewController:(UIViewController *)viewController {
  [viewController willMoveToParentViewController:nil];
  [viewController.view removeFromSuperview];
  [viewController removeFromParentViewController];
}

@end

NS_ASSUME_NONNULL_END
