// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

@class BZRProduct, SPXSubscriptionManager;

@protocol BZRProductsManager, BZRProductsInfoProvider, SPXAlertViewModel;

/// Delegate for \c SPXSubscriptionManager, used by the manager to present UI during asynchronous
/// operations. The manager may use it to present alerts successful completion of some operations or
/// on failure of some other operations and to present the feedback mail composer.
@protocol SPXSubscriptionManagerDelegate <NSObject>

/// Invoked by the subscription manager when an alert is needed to be shown to the user. The
/// \c viewModel defines the title, message and buttons of the alert.
- (void)presentAlertWithViewModel:(id<SPXAlertViewModel>)viewModel;

/// Invoked by the subscription manager when the user requested to send a feedback email. When
/// the mail composer is dismissed \c completionHandler should be invoked.
- (void)presentFeedbackMailComposerWithCompletionHandler:(LTVoidBlock)completionHandler;

@end

/// Manager used to handle subscription purchasing and restoration, with an appropriate localized
/// messages to the user on success or failure.
@interface SPXSubscriptionManager : NSObject

/// Initializes with shared \c productsInfoProvider and \c productsManager pulled from Objection.
- (instancetype)init;

/// Initializes with \c productsInfoProvider used to get the current subscription status and
/// \c productsManager is used to purchase subscriptions and restore purchases.
- (instancetype)initWithProductsInfoProvider:(id<BZRProductsInfoProvider>)productsInfoProvider
                             productsManager:(id<BZRProductsManager>)productsManager
    NS_DESIGNATED_INITIALIZER;

/// Block invoked after product information fetch is completed. On success \c products is returned
/// and error is \c nil. On failure, \c products is \c nil and \c error will contain an appropriate
/// error description.
typedef void (^SPXFetchProductsCompletionBlock)
    (NSDictionary<NSString *, BZRProduct *> * _Nullable products, NSError * _Nullable error);

/// Fetches the given subscription products information specified by \c productIdentifiers from
/// Apple's iTunesConnect. On success, \c completionHandler is invoked with a dictionary mapping
/// identifiers to \c BZRProduct. If a product's price info couldn't be fetched, it will not appear
/// in the returned dictionary. On fetching error \c completionHandler is invoked with \c error code
/// \c BZRErrorCodeProductsMetadataFetchingFailed if failed to fetch the information or with error
/// code \c BZRErrorCodeInvalidProducts if the product are invalid, \c products will set to \c nil.
- (void)fetchProductsInfo:(NSSet<NSString *> *)productIdentifiers
        completionHandler:(SPXFetchProductsCompletionBlock)completionHandler;

/// Makes a purchase of the subscription specified by \c productIdentifier. \c completionHandler
/// is invoked when the purchase process has completed with \c success set to \c YES if the purchase
/// was successful and \c NO otherwise. If there is an error during the purchasing process, an alert
/// with 3 buttons is presented - a "Not Now" button that cancels the purchase, "Try Again" button
/// that will try to continue the purchase process from the point that the previous attempt has
/// failed and a "Contact Us" button that will present the feedback mail composer.
/// \c completionHandler is invoked on the main thread.
- (void)purchaseSubscription:(NSString *)productIdentifier
           completionHandler:(LTBoolCompletionBlock)completionHandler;

/// Restore and updates the subscription information. \c completionHandler is invoked when the
/// restoration process was completed with \c success set to \c YES if the purchase was successful
/// and \c NO otherwise. If there is an error during the restoration process, an alert with 3
/// buttons is presented - a "Not Now" button that cancels the restoration, "Try Again" button
/// that will restart the restoration process, and a "Contact Us" button that will present the
/// feedback mail composer. \c completionHandler is invoked on the main thread.
- (void)restorePurchasesWithCompletionHandler:(LTBoolCompletionBlock)completionHandler;

/// Delegate used to present UI to the user during asynchronous operations.
@property (weak, nonatomic, nullable) id<SPXSubscriptionManagerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
