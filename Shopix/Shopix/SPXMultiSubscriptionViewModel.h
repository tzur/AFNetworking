// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionManager.h"

NS_ASSUME_NONNULL_BEGIN

@class LTValueObject, SPXColorScheme;

@protocol SPXAlertViewModel, SPXSubscriptionButtonsPageViewModel, SPXSubscriptionTermsViewModel,
    SPXSubscriptionTermsViewModel;

#pragma mark -
#pragma mark SPXMultiSubscriptionViewModel protocol
#pragma mark -

/// View-Model for \c SPXMultiSubscriptionScreenViewController.
@protocol SPXMultiSubscriptionViewModel <NSObject>

/// Invoked after the subscription screen view was loaded and its view hierarchy was initialized and
/// is ready for presentation.
- (void)viewDidSetup;

/// Invoked when a subscription button with the index \c buttonIndex is pressed inside a page with
/// index \c pageIndex.
- (void)subscriptionButtonPressed:(NSUInteger)buttonIndex atPageIndex:(NSUInteger)pageIndex;

/// Invoked when the restore purchases button is pressed.
- (void)restorePurchasesButtonPressed;

/// Invoked when the scrolling position has changed to \c position.
- (void)scrolledToPosition:(CGFloat)position;

/// Invoked when the dismiss button is pressed.
- (void)dismissButtonPressed;

/// Page view models, used to define page views with title, subtitle, subscription buttons and
/// the background video that appears when the page is in focus.
@property (readonly, nonatomic) NSArray<id<SPXSubscriptionButtonsPageViewModel>> * pageViewModels;

/// Page index that is currently active.
@property (readonly, nonatomic) NSUInteger activePageIndex;

/// If /c YES, a footnote is shown to the user to clarify the exact nature of the billing for
/// subscription products for which the retail price is different than the presented price.
@property (readonly, nonatomic) BOOL showNonMonthlyBillingFootnote;

/// Terms view model, used to define the terms text, terms-of-use and privacy documents.
@property (readonly, nonatomic) id<SPXSubscriptionTermsViewModel> termsViewModel;

/// Color scheme for the subscription view and its subviews.
@property (readonly, nonatomic) SPXColorScheme *colorScheme;

/// Signal that sends an alert view model when requested to show an alert to the user on success or
/// failure. The receiver should present an alert with the given \c id<SPXAlertViewModel> and invoke
/// the action block on each button press event.
@property (readonly, nonatomic) RACSignal<id<SPXAlertViewModel>> *alertRequested;

/// Signal that sends value when requested to show a mail composer to the user. The \c value is
/// a \c LTVoidBlock that should called when the mail composer is dismissed.
@property (readonly, nonatomic) RACSignal<LTVoidBlock> *feedbackComposerRequested;

/// \c YES if the activity indicator should be visible, \c NO otherwise. KVO compliant.
@property (readonly, nonatomic) BOOL shouldShowActivityIndicator;

/// Sends UI interactions events and restore / purchase subscription success or failure events.
@property (readonly, nonatomic) RACSignal<LTValueObject *> *events;

/// Hot signal that sends a \c RACUnit value when the view should be dismissed. The signal delivers
/// on the main thread.
@property (readonly, nonatomic) RACSignal<RACUnit *> *dismissRequested;

@end

#pragma mark -
#pragma mark SPXMultiSubscriptionViewModel class
#pragma mark -

/// Default implementation of the \c SPXMultiSubscriptionViewModel protocol.
@interface SPXMultiSubscriptionViewModel : NSObject <SPXMultiSubscriptionViewModel>

- (instancetype)init NS_UNAVAILABLE;

/// Same as the designated initializer. \c colorScheme is pulled from Objection, and
/// \c subscriptionManager is set to the default manager.
- (instancetype)initWithPages:(NSArray<id<SPXSubscriptionButtonsPageViewModel>> *)pageViewModels
             initialPageIndex:(NSUInteger)initialPageIndex
               termsViewModel:(id<SPXSubscriptionTermsViewModel>)termsViewModel;

/// Initializes with:
///
/// \c pageViewModels used to define page views with title, subtitle, subscription buttons and
/// the background video that appears when the page is in focus.
///
/// \c initialPageIndex the index that will be in focus when the view is displayed. must be in range
/// <tt>[0, pageViewModels - 1]</tt>, otherwise a \c NSInvalidArgumentException is raised.
///
/// \c termsViewModel used to define the terms text, terms-of-use and privacy documents.
///
/// \c colorScheme defines the color scheme for the subscription view and its subviews.
///
/// \c subscriptionManager used to handle products information fetching, subscription purchasing and
/// restoration.
- (instancetype)initWithPages:(NSArray<id<SPXSubscriptionButtonsPageViewModel>> *)pageViewModels
             initialPageIndex:(NSUInteger)initialPageIndex
               termsViewModel:(id<SPXSubscriptionTermsViewModel>)termsViewModel
                  colorScheme:(SPXColorScheme *)colorScheme
          subscriptionManager:(SPXSubscriptionManager *)subscriptionManager
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
