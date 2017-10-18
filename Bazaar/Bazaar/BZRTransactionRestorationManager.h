// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

@protocol BZRRestorationPaymentQueue;

NS_ASSUME_NONNULL_BEGIN

/// Manager used to restore completed transactions.
@interface BZRTransactionRestorationManager : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c paymentQueue, used to restore transactions with. Setting \c paymentQueue's
/// \c restorationDelegate after the initialization of the receiver is considered undefined
/// behavior. \c applicationUserID is an optional unique identifier for the user’s account that is
/// used to restore transactions with.
///
/// @Note The \c applicationUserID is a user ID provided by the application that uniquely identifies
/// the user (i.e. it must be different for different users and identical for the same user across
/// devices). If it is not \c nil, it will be used when making purchases to assist with fraud
/// detection. For more information about the application user identifier follow this link:
/// https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Chapters/RequestPayment.html#//apple_ref/doc/uid/TP40008267-CH4-SW6
- (instancetype)initWithPaymentQueue:(id<BZRRestorationPaymentQueue>)paymentQueue
                   applicationUserID:(nullable NSString *)applicationUserID
    NS_DESIGNATED_INITIALIZER;

/// Restores all previously completed transactions made by the user, using \c applicationUserID if
/// it is not \c nil.
///
/// Returns a signal that initiates a restoration request upon subscription and sends the restored
/// transaction objects as they arrive, one by one. The values sent are \c SKPaymentTransaction
/// instances in the state of \c SKPaymentTransactionStateRestored. The signal completes when the
/// all previous transactions were restored and errs if restoration fails for any reason.
- (RACSignal<SKPaymentTransaction *> *)restoreCompletedTransactions;

@end

NS_ASSUME_NONNULL_END
