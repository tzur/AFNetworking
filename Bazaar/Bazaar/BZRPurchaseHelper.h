// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRAggregatedReceiptValidationStatusProvider;

/// Protocol for providing information regarding the subscription.
@protocol BZRPurchaseHelper <NSObject>

/// Returns \c YES if the purchase should be proceeded with, and \c NO otherwise.
- (BOOL)shouldProceedWithPurchase:(SKPayment *)payment;

@end

/// Default implementation of the \c BZRPurchaseHelper protocol, that determines that the purchase
/// should be proceeded with only if there is no active subscription.
@interface BZRPurchaseHelper : NSObject <BZRPurchaseHelper>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c aggregatedReceiptProvider, used to provide the receipt validation status.
- (instancetype)initWithAggregatedReceiptProvider:
    (BZRAggregatedReceiptValidationStatusProvider *)aggregatedReceiptProvider;

@end

NS_ASSUME_NONNULL_END
