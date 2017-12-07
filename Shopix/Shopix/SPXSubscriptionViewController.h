// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

@protocol SPXAlertViewControllerProvider, SPXSubscriptionButtonsFactory,
    SPXFeedbackComposeViewControllerProvider, SPXSubscriptionViewModel,
    SPXSubscriptionTermsViewModel, SPXSubscriptionVideoPageViewModel;

/// View controller representing a subscription screen, presenting to the user different
/// subscription types that he can purchase, along with description and videos for more information
/// about the subscription features, special offers and discounts. The controller also allows the
/// user to restore previous purchases, to see the terms of use and privacy policy. The view layout
/// is specialized for video pages and horizontal subscription buttons layout.
@interface SPXSubscriptionViewController : UIViewController

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

/// Same as the designated initializer. \c alertControllerProvider is set to the default provider
/// and \c subscriptionButtonsProvider is set to \c SPXSubscriptionGradientButtonsProvider.
- (instancetype)initWithViewModel:(id<SPXSubscriptionViewModel>)viewModel
    mailComposerProvider:(id<SPXFeedbackComposeViewControllerProvider>)mailComposerProvider;

/// Initializes with \c viewModel for the subscription view configuration,
/// \c alertControllerProvider for creating the success and failure alerts, \c mailComposerProvider
/// for creating the feedback view controller, \c subscriptionButtonsProvider for creating the
/// subscription buttons and \c backgroundView the view on the background, if \c nil the background
/// color from \c viewModel.colorsTheme is taken.
- (instancetype)initWithViewModel:(id<SPXSubscriptionViewModel>)viewModel
          alertControllerProvider:(id<SPXAlertViewControllerProvider>)alertControllerProvider
             mailComposerProvider:(id<SPXFeedbackComposeViewControllerProvider>)mailComposerProvider
       subscriptionButtonsFactory:(id<SPXSubscriptionButtonsFactory>)subscriptionButtonsFactory
    NS_DESIGNATED_INITIALIZER;

/// Background view, stretched to the size of the view.
@property (strong, nonatomic, nullable) UIView *backgroundView;

/// Hot signal that sends a \c RACUnit value when the view should be dismissed. delivers on the
/// main thread.
@property (readonly, nonatomic) RACSignal<RACUnit *> *dismissRequested;

@end

NS_ASSUME_NONNULL_END
