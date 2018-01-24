// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRStoreKitTypedefs.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BZRPaymentQueuePaymentsDelegate;

/// \c BZRPaymentsPaymentQueue provides an interface for making payments and sending updates
/// regarding payment transactions.
@protocol BZRPaymentsPaymentQueue <NSObject>

/// Adds a payment request. Will initiate sending updates of transaction associated with \c payment
/// to \c paymentsDelegate.
- (void)addPayment:(SKPayment *)payment;

/// Delegate that will be receiving updates regarding payment transactions.
@property (weak, nonatomic, nullable) id<BZRPaymentQueuePaymentsDelegate> paymentsDelegate;

@end

/// Protocol for delegates that want to receive updates regarding payment transactions.
///
/// @note Payment transactions are added to the payment queue in response to payment requests made
/// by calling \c -[BZRPaymentQueue addPayment:].
@protocol BZRPaymentQueuePaymentsDelegate <NSObject>

/// Invoked when \c paymentQueue informs its delegates that the state of the payment transactions in
/// \c transactions was updated.
- (void)paymentQueue:(id<BZRPaymentsPaymentQueue>)paymentQueue
    paymentTransactionsUpdated:(BZRPaymentTransactionList *)transactions;

@optional

/// Invoked when \c paymentQueue informs its delegates that \c transactions were finished and
/// removed from the queue. \c transactions will contain only payment transactions and no
/// restoration transactions.
- (void)paymentQueue:(id<BZRPaymentsPaymentQueue>)paymentQueue
    paymentTransactionsRemoved:(BZRPaymentTransactionList *)transactions;

/// Returns \c YES if a purchase intiated from the App Store should be proceeded with and
/// \c NO otherwise.
- (BOOL)shouldProceedWithPromotedIAP:(SKProduct *)product payment:(SKPayment *)payment;

@end

NS_ASSUME_NONNULL_END
