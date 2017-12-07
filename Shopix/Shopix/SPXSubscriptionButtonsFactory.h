// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

@class SPXSubscriptionDescriptor;

/// Protocol for creating subscription buttons by subscription information.
@protocol SPXSubscriptionButtonsFactory

/// Returns a new button, filled with the required information from the given
/// \c subscriptionDescriptor. The receiver need to observe \c subscriptionDescriptor.priceInfo
/// property for changes and update the button view accordingly. \c index is the index of the
/// buttons out of \c buttonsCount the total number of buttons.
- (UIControl *)createSubscriptionButtonWithSubscriptionDescriptor:
    (SPXSubscriptionDescriptor *)subscriptionDescriptor atIndex:(NSUInteger)index
                                                          outOf:(NSUInteger)buttonsCount;

@end

NS_ASSUME_NONNULL_END
