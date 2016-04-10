// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Category for easing addition and removal of view controllers as children of other view
/// controllers.
@interface UIViewController (Containment)

/// Adds the given \c viewController as a child of the receiver, and adds its \c view as a subview
/// of the receiver's \c view.
- (void)wf_addChildViewController:(UIViewController *)viewController;

/// Inserts the given \c viewController as a child of the receiver, and adds its root \c view as a
/// subview of the receiver's \c view, below the given \c subview.
- (void)wf_insertChildViewController:(UIViewController *)viewController
                        belowSubview:(UIView *)subview;

/// Inserts the given \c viewController as a child of the receiver, and adds its root \c view as a
/// subview of the receiver's \c view, above the given \c subview.
- (void)wf_insertChildViewController:(UIViewController *)viewController
                        aboveSubview:(UIView *)subview;

/// Adds the given \c viewController as a child of the receiver, and adds its root view as a subview
/// of the given \c view.
- (void)wf_addChildViewController:(UIViewController *)viewController toView:(UIView *)view;

/// Inserts the given \c viewController as a child of the receiver, and adds its root \c view as a
/// subview of the given \c view, below the given \c subview.
- (void)wf_insertChildViewController:(UIViewController *)viewController toView:(UIView *)view
                        belowSubview:(UIView *)subview;

/// Inserts the given \c viewController as a child of the receiver, and adds its root \c view as a
/// subview of the given \c view, above the given \c subview.
- (void)wf_insertChildViewController:(UIViewController *)viewController toView:(UIView *)view
                        aboveSubview:(UIView *)subview;

/// Removes the given \c viewController as a child of the receiver, and removes its root \c view as
/// a subview of the receiver's view.
- (void)wf_removeChildViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
