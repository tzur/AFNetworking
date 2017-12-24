// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

@protocol SPXAlertViewControllerProvider, SPXSubscriptionButtonsFactory,
    SPXFeedbackComposeViewControllerProvider, SPXMultiSubscriptionViewModel,
    SPXSubscriptionTermsViewModel;

/// View controller for subscription screen that offers subscription products of different groups.
/// It accepts one or more groups of subscription products. Each products group is associated with
/// title, subtitle and a background video. The products of each group are displayed inside a
/// container as a horizontal layout of subscription buttons along with the title and subtitle
/// associated with that group. The video associated with the group is being played in the
/// background when the group is in focus. For each product within a group, a subscription button
/// initiates a purchase when tapped. The view controller also allows the user to restore
/// previous purchases, to see the terms of use and privacy policy.
@interface SPXMultiSubscriptionViewController : UIViewController

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

/// Same as the designated initializer. \c alertControllerProvider is set to the default provider
/// and \c subscriptionButtonsFactory is set to \c SPXMultiSubscriptionGradientButtonsFactory.
- (instancetype)initWithViewModel:(id<SPXMultiSubscriptionViewModel>)viewModel
    mailComposerProvider:(id<SPXFeedbackComposeViewControllerProvider>)mailComposerProvider;

/// Same as the designated initializer. \c alertControllerProvider is set to the default provider.
- (instancetype)initWithViewModel:(id<SPXMultiSubscriptionViewModel>)viewModel
             mailComposerProvider:(id<SPXFeedbackComposeViewControllerProvider>)mailComposerProvider
       subscriptionButtonsFactory:(id<SPXSubscriptionButtonsFactory>)subscriptionButtonsFactory;

/// Initializes with \c viewModel for the subscription view configuration,
/// \c alertControllerProvider for creating the success and failure alerts, \c mailComposerProvider
/// for creating the feedback view controller, \c subscriptionButtonsFactory for creating the
/// subscription buttons.
- (instancetype)initWithViewModel:(id<SPXMultiSubscriptionViewModel>)viewModel
          alertControllerProvider:(id<SPXAlertViewControllerProvider>)alertControllerProvider
             mailComposerProvider:(id<SPXFeedbackComposeViewControllerProvider>)mailComposerProvider
       subscriptionButtonsFactory:(id<SPXSubscriptionButtonsFactory>)subscriptionButtonsFactory
    NS_DESIGNATED_INITIALIZER;

/// Hot signal that sends a \c RACUnit value when the view should be dismissed. Delivers on the
/// main thread.
@property (readonly, nonatomic) RACSignal<RACUnit *> *dismissRequested;

@end

NS_ASSUME_NONNULL_END

