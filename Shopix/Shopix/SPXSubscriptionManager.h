// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

/// Generic group for malformed product IDs.
static NSString *const kBZRGenericGroup = @"GenericGroupForMalformedProductID";

@class BZRProduct, BZRReceiptInfo, BZRReceiptSubscriptionInfo;

@protocol BZRProductsInfoProvider, BZRProductsManager, BZRUserIDProvider, SPXAlertViewModel;

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
/// Apple's iTunesConnect. On success, \c completionHandler is invoked on the main thread with a
/// dictionary mapping identifiers to \c BZRProduct. If a product's price info couldn't be fetched,
/// it will not appear in the returned dictionary. On failure, \c completionHandler is invoked with
/// \c products set to \c nil and \c error will contain error information.
///
/// @note On failure \c error.code may be either \c BZRErrorCodeProductMetadataFetchingFailed or
/// \c BZRErrorCodeInvalidProductIdentifier.
- (void)fetchProductsInfo:(NSSet<NSString *> *)productIdentifiers
        completionHandler:(SPXFetchProductsCompletionBlock)completionHandler;

/// Block invoked on completion of \c purchaseSubscription:completionHandler: method. On successful
/// completion the \c subscriptionInfo parameter will contain the latest subscription information
/// as provided by Bazaar, on failure \c error will contain error information.
typedef void (^SPXPurchaseSubscriptionCompletionBlock)
    (BZRReceiptSubscriptionInfo * _Nullable subscriptionInfo, NSError * _Nullable error);

/// Purchases the subscription product specified by \c productIdentifier. \c completionHandler is
/// invoked on the main thread when the purchase process has completed with \c subscriptionInfo and
/// \c error set to \c nil if purchase was successful, otherwise \c subscriptionInfo will be \c nil
/// and \c error will contain the error information.
///
/// If there is an error during the purchasing process, the delegate is requested to present an
/// alert with 3 buttons - a "Not Now" button that cancels the operation, "Try Again" button that
/// will try to continue the operation from the point that the previous attempt has failed (e.g.
/// if the previous attempt has failed during receipt validation the next attempt will only try to
/// validate the receipt) and a "Contact Us" button that will ask the delegate to present the
/// feedback mail composer.
///
/// @note If the user has actively cancelled the purchase (e.g. by pressing the cancel button of the
/// authentication dialog) or the user is not allowed to do the purchase then \c completionHandler
/// is invoked with \c subscriptionInfo set to \c nil and \c error.code will be
/// \c BZRErrorCodeOperationCancelled in the former case and \c BZRErrorCodePurchaseNotAllowed in
/// the latter one.
- (void)purchaseSubscription:(NSString *)productIdentifier
           completionHandler:(SPXPurchaseSubscriptionCompletionBlock)completionHandler;

/// Block invoked on completion of \c purchaseSubscription:completionHandler: method. On successful
/// completion the \c receiptInfo parameter will contain the latest receipt information as provided
/// by Bazaar, on failure \c error will contain error information.
typedef void (^SPXRestorationCompletionBlock)
    (BZRReceiptInfo * _Nullable receiptInfo, NSError * _Nullable error);

/// Restores and updates the subscription information. \c completionHandler is invoked on the main
/// thread when the restoration process has completed with \c receiptInfo and \c error set to \c nil
/// if the restoration was successful, otherwise \c receiptInfo will be \c nil and \c error will
/// contain error information.
///
/// If there is an error during the purchasing process, the delegate is requested to present an
/// alert with 3 buttons - a "Not Now" button that cancels the operation, "Try Again" button that
/// will try to restore purchases again and a "Contact Us" button that will ask the delegate to
/// present the feedback mail composer.
///
/// @note If the user has actively cancelled the purchase (e.g. by pressing the cancel button of the
/// authentication dialog) then \c completionHandler is invoked with \c subscriptionInfo set to
/// \c nil and \c error.code will be \c BZRErrorCodeOperationCancelled.
- (void)restorePurchasesWithCompletionHandler:(SPXRestorationCompletionBlock)completionHandler;

/// Returns \c YES if user is eligible for a discount on the subscription product
/// \c subscriptionProduct, \c NO otherwise.
- (BOOL)eligibleForIntroductoryDiscountOnSubscription:(BZRProduct *)subscriptionProduct;

/// Specifies a unique identifier of the user. \c nil signifies that the user ID is currently
/// unavailable.
@property (readonly, nonatomic, nullable) NSString *userID;

/// Delegate used to present UI to the user during asynchronous operations.
@property (weak, nonatomic, nullable) id<SPXSubscriptionManagerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
