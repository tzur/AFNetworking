// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionButtonsPageView.h"

@protocol SPXSubscriptionButtonsFactory, SPXSubscriptionButtonsPageViewModel;

NS_ASSUME_NONNULL_BEGIN

/// Category for creating a buttons page view according to a given view model and buttons factory.
@interface SPXSubscriptionButtonsPageView (ViewModel)

/// Creates a buttons page view with the given \c pageViewModel and its buttons with
/// \c buttonsFactory.
+ (instancetype)buttonsPageViewWithViewModel:(id<SPXSubscriptionButtonsPageViewModel>)pageViewModel
                              buttonsFactory:(id<SPXSubscriptionButtonsFactory>)buttonsFactory;

@end

NS_ASSUME_NONNULL_END
