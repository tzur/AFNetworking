// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ben Yohay.

@class SPXConsumablesOrderSummary, SPXRedeemStatus;

@protocol BZRProductsManager, SPXAlertViewModel;

NS_ASSUME_NONNULL_BEGIN

/// Delegate for \c SPXConsumablesManager, used by the manager to present UI during asynchronous
/// operations. The manager may use it to present alerts successful completion of some operations or
/// on failure of some other operations and to present the feedback mail composer.
@protocol SPXConsumablesManagerDelegate <NSObject>

/// Invoked by the manager when an alert is needed to be shown to the user. \c error provides
/// information about the error. Its possible error codes are \c
/// SPXErrorCodeOrderSummaryCalculationFailed and \c SPXErrorCodePlacingOrderFailed, and it can also
/// have an underlying error. \c tryAgainAction should be invoked when the user wants to retry the
/// failed operation. It will be \c nil if it is not possible to retry it. \c contactUsAction should
/// be invoked when the user wants to contact us. \c cancelAction should be invoked when the user
/// doesn't want to retry the operation.
- (void)presentAlertWithError:(NSError *)error tryAgainAction:(nullable LTVoidBlock)tryAgainAction
              contactUsAction:(LTVoidBlock)contactUsAction cancelAction:(LTVoidBlock)cancelAction;

/// Invoked by the manager when the user requested to send a feedback email. When the mail composer
/// is dismissed \c completionHandler should be invoked.
- (void)presentFeedbackMailComposerWithCompletionHandler:(LTVoidBlock)completionHandler;

@end

/// Manager used to purchase consumable items and provide the consumable items that were already
/// purchased along with the credit that the user has.
@interface SPXConsumablesManager : NSObject

/// Initializes with shared \c productsManager pulled from Objection.
- (instancetype)init;

/// Initializes with \c productsManager used to calculate order summary and redeem consumable items.
- (instancetype)initWithProductsManager:(id<BZRProductsManager>)productsManager
    NS_DESIGNATED_INITIALIZER;

/// Returns the order summary used to consume the items specified by \c consumableItemIDToType.
///
/// Returns a signal that fetches the credit that user has and the required credit for each
/// item specified in \c consumableItemIDToType and sends them. The required credit for each item is
/// provided in \c consumablesRequiredCredit. An item that was already redeemed will have \c 0
/// required credit and \c isOwned set to \c YES. The signal errs if there was an error calculating
/// the summary and the user decided not to retry it.
///
/// @note If there is an error during the fetching process, the delegate is requested to present an
/// alert with 3 buttons - a "Not Now" button that cancels the operation, "Try Again" button that
/// will try to continue the operation from the point that the previous attempt has failed (e.g.
/// if the previous attempt has failed during receipt validation the next attempt will only try to
/// validate the receipt) and a "Contact Us" button that will ask the delegate to present the
/// feedback mail composer.
- (RACSignal<SPXConsumablesOrderSummary *> *)calculateOrderSummary:(NSString *)creditType
    consumableItemIDToType:(NSDictionary<NSString *, NSString *> *)consumableItemIDToType;

/// Redeems the credit of the user with the consumable items specified in \c orderSummary. If the
/// user doesn't have enough credit, the user will be asked to purchase more credit with the product
/// specified by \c productIdentifier.
///
/// Returns a signal that first checks if the user has enough credit to redeem all the consumable
/// items specified in \c orderSummary. If the user has enough, the correct amount of credit is
/// redeemed according to the consumable items. If the user doesn't have enough credit, a purchase
/// is initiated using the product specified by \c productIdentifier so that the user will have
/// enough credit to redeem. Then the credit is redeemed for the consumable items. The signal sends
/// an object describing the user balance after redeeming and the redeemed items. Then the signal
/// completes. The signal errs in one of the following cases:
/// - The user actively cancelled the purchase for more credit. The error code will be
/// \c BZRErrorCodeOperationCancelled.
/// - The product is invalid or the quantity of the product to purchase is invalid. The error code
/// will be \c BZRErrorCodeInvalidProductForPurchasing or
/// \c BZRErrorCodeInvalidQuantityForPurchasing respectively.
/// - During the redeem process, the user may not have enough credit (even though enough credit was
/// purchased). In this case the error code will be \c BZRErrorCodeValidatricksRequestFailed.
/// - One of the operations failed and the user decided not to retry it.
/// In case the error came from Validatricks the error may information regarding the error in the
/// property \c bzr_validatricksErrorInfo.
///
/// @note It is assumed that the product specified by \c productIdentifier grants \c 1 credit.
///
/// @note In case the user already owns a consumable item, credit won't be redeemed for it again.
///
/// @note If there is an error during the purchasing process, the delegate is requested to present
/// an alert with 3 buttons - a "Not Now" button that cancels the operation, "Try Again" button
/// that will try to continue the operation from the point that the previous attempt has failed
/// (e.g. if the previous attempt has failed during receipt validation the next attempt will only
/// try to validate the receipt) and a "Contact Us" button that will ask the delegate to present the
/// feedback mail composer.
- (RACSignal<SPXRedeemStatus *> *)placeOrder:(SPXConsumablesOrderSummary *)orderSummary
                       withProductIdentifier:(NSString *)productIdentifier;

/// Delegate used to present UI to the user during asynchronous operations.
@property (weak, nonatomic, nullable) id<SPXConsumablesManagerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
