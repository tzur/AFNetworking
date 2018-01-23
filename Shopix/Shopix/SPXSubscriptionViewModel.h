// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionManager.h"

NS_ASSUME_NONNULL_BEGIN

@class LTValueObject, SPXSubscriptionDescriptor, SPXColorScheme;

@protocol SPXAlertViewModel, SPXSubscriptionVideoPageViewModel, SPXSubscriptionTermsViewModel,
    SPXSubscriptionTermsViewModel;

/// Possible values of the products fetching strategy.
LTEnumDeclare(NSUInteger, SPXFetchProductsStrategy,
  /// States that the products information will be taken from the cached products information if it
  /// exists, otherwise it will be fetched.
  SPXFetchProductsStrategyIfNeeded,
  /// States that the products information will re-fetched every time the view is loaded.
  SPXFetchProductsStrategyAlways
);

#pragma mark -
#pragma mark SPXSubscriptionViewModel protocol
#pragma mark -

/// View-Model for \c SPXSubscriptionScreenViewController.
@protocol SPXSubscriptionViewModel <NSObject>

/// Invoked when a subscription button with the index \c buttonIndex is pressed. \c buttonIndex
/// is referring to the subscription descriptor index in \c subscriptionDescriptors.
- (void)subscriptionButtonPressed:(NSUInteger)buttonIndex;

/// Invoked when the restore purchases button is pressed.
- (void)restorePurchasesButtonPressed;

/// Invoked when the active page's video playback has finished.
- (void)activePageDidFinishVideoPlayback;

/// Invoked when the paging view scrolled to \c position.
- (void)pagingViewScrolledToPosition:(CGFloat)position;

/// Fetches the products information and updates \c subscriptionDescriptors.
- (void)fetchProductsInfo;

/// Descriptors of the subscription products to show to the user. Each descriptor holds all the
/// information that is necessary for purchasing.
@property (readonly, nonatomic) NSArray<SPXSubscriptionDescriptor *> *subscriptionDescriptors;

/// Preferred subscription product index. The button for this subscription product should be
/// highlighted.
@property (readonly, nonatomic, nullable) NSNumber *preferredProductIndex;

/// Page view models, used to define page views with video, title and subtitle.
@property (readonly, nonatomic) NSArray<id<SPXSubscriptionVideoPageViewModel>> * pageViewModels;

/// Terms view model, used to define the terms text, terms-of-use and privacy documents.
@property (readonly, nonatomic) id<SPXSubscriptionTermsViewModel> termsViewModel;

/// If /c YES, a footnote is shown to the user to clarify the exact nature of the billing for
/// subscription products for which the retail price is different than the presented price.
@property (readonly, nonatomic) BOOL showNonMonthlyBillingFootnote;

/// Color scheme for the subscription view and its subviews.
@property (readonly, nonatomic) SPXColorScheme *colorScheme;

/// Signal that sends a page index that the view should scroll to.
@property (readonly, nonatomic) RACSignal<NSNumber *> *pagingViewScrollRequested;

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
#pragma mark SPXSubscriptionViewModel class
#pragma mark -

/// Default implementation of the \c SPXSubscriptionViewModel protocol.
@interface SPXSubscriptionViewModel : NSObject <SPXSubscriptionViewModel>

- (instancetype)init NS_UNAVAILABLE;

/// Same as the designated initializer. \c colorScheme is pulled from Objection,
/// \c showNonMonthlyBillingFootnote is set to \c YES, \c subscriptionManager is set to the default
/// manager and \c fetchProductsStrategy is set to \c SPXFetchProductsStrategyAlways.
- (instancetype)
    initWithSubscriptionDescriptors:(NSArray<SPXSubscriptionDescriptor *> *)subscriptionDescriptors
              preferredProductIndex:(nullable NSNumber *)preferredProductIndex
                     pageViewModels:(NSArray<id<SPXSubscriptionVideoPageViewModel>> *)pageViewModels
                     termsViewModel:(id<SPXSubscriptionTermsViewModel>)termsViewModel;

/// Initializes with:
///
/// \c subscriptionDescriptors defines the subscription products that will be offered to the user on
/// the subscribe screen. The order of the array determines the order of the displayed buttons.
///
/// \c preferredProductIndex is a preferred subscription product index. The button for this
/// subscription product will be highlighted. Must be in range
//// <tt>[0, subscriptionDescriptors.count - 1]</tt>, otherwise an \c NSInvalidArgumentException is
/// raised. If set to \c nil none of the buttons will be highlighted.
///
/// \c pageViewModels used to define page views with video, title and subtitle.
///
/// c \showNonMonthlyBillingFootnote used to show a clarification about billing for subscription
/// products for which the retail price is different than the presented price.
///
/// \c termsViewModel used to define the terms text, terms-of-use and privacy documents.
///
/// \c colorScheme defines the color scheme for the subscription view and its subviews.
///
/// \c subscriptionManager used to handle products information fetching, subscription purchasing and
/// restoration.
///
/// \c fetchProductsStrategy used to specify the strategy for products information fetching.
- (instancetype)
    initWithSubscriptionDescriptors:(NSArray<SPXSubscriptionDescriptor *> *)subscriptionDescriptors
              preferredProductIndex:(nullable NSNumber *)preferredProductIndex
                     pageViewModels:(NSArray<id<SPXSubscriptionVideoPageViewModel>> *)pageViewModels
      showNonMonthlyBillingFootnote:(BOOL)showNonMonthlyBillingFootnote
                     termsViewModel:(id<SPXSubscriptionTermsViewModel>)termsViewModel
                        colorScheme:(SPXColorScheme *)colorScheme
                subscriptionManager:(SPXSubscriptionManager *)subscriptionManager
              fetchProductsStrategy:(SPXFetchProductsStrategy *)fetchProductsStrategy
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
