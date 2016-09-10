// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

/// Fake \c SKPaymentTransaction with mutable \c transactionState and \c downloads.
@interface BZRFakePaymentTransaction : SKPaymentTransaction <NSCopying>

/// Initializes with \c payment set to \c nil.
- (instancetype)init;

/// Intiializes with \c payment.
- (instancetype)initWithPayment:(nullable SKPayment *)payment NS_DESIGNATED_INITIALIZER;

/// State of the transaction.
@property (readwrite, nonatomic) SKPaymentTransactionState transactionState;

/// Available downloads for this transaction.
@property (readwrite, nonatomic) NSArray<SKDownload *> *downloads;

/// Error that indicates failure in the transaction.
@property (readwrite, nonatomic) NSError *error;

@end

NS_ASSUME_NONNULL_END
