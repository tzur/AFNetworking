// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Hagai Weinfeld.

#import "BZRStoreKitTypedefs.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BZRPaymentsPaymentQueue, BZRPurchaseHelper;

/// Class for managing in-app purchases from Apple's AppStore and following their corresponding
/// \c SKPaymentTransaction's state as reported by an \c BZRPaymentsPaymentQueue.
///
/// A manager may receive updates for purchases that were not initiated by it. These are forwarded
/// to \c unhandledTransactionsSignal.
@interface BZRPurchaseManager : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initialize the receiver with \c paymentQueue, used to initiate payment requests. Setting
/// \c paymentQueue's \c paymentsDelegate after the initialization of the receiver is considered
/// undefined behavior. \c applicationUserID is used to identify the user while making a payment
/// request.
///
/// The \c applicationUserID is a user ID provided by the application that uniquely identifies the
/// user (i.e. it must be different for different users and identical for the same user across
/// devices). If it is not \c nil, it will be used when making purchases to assist with
/// fraud detection. For more information about the application user identifier follow this link:
/// https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Chapters/RequestPayment.html#//apple_ref/doc/uid/TP40008267-CH4-SW6
- (instancetype)initWithPaymentQueue:(id<BZRPaymentsPaymentQueue>)paymentQueue
                   applicationUserID:(nullable NSString *)applicationUserID
                      purchaseHelper:(id<BZRPurchaseHelper>)purchaseHelper
    NS_DESIGNATED_INITIALIZER;

/// Initiates a payment request for \c product with \c quantity.
///
/// Returns a signal that initiates a payment request upon subscription and sends
/// \c SKPaymentTransaction updates for every transaction update that belongs to the purchasing
/// process of that payment. The signal completes when the transaction has finished. This occurs
/// only after \c finishTransaction was invoked for that transaction.
///
/// @note If the purchase was cancelled, the signal will err with an error code
/// \c BZRErrorCodeOperationCancelled.
- (RACSignal<SKPaymentTransaction *> *)purchaseProduct:(SKProduct *)product
                                              quantity:(NSUInteger)quantity;

/// Sends transactions that are received by the delegate calls and are not associated with a
/// purchase made using the receiver. The transactions are sent in an array batch. The signal
/// completes when the receiver is deallocated. The signal doesn't err.
@property (readonly, nonatomic) RACSignal<BZRPaymentTransactionList *> *unhandledTransactionsSignal;

@end

NS_ASSUME_NONNULL_END
