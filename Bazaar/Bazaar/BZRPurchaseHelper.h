// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRMultiAppReceiptValidationStatusProvider;

/// Protocol for providing information regarding the subscription.
@protocol BZRPurchaseHelper <NSObject>

/// Returns \c YES if the purchase should be proceeded with, and \c NO otherwise.
- (BOOL)shouldProceedWithPurchase:(SKPayment *)payment;

@end

/// Default implementation of the \c BZRPurchaseHelper protocol, that determines that the purchase
/// should be proceeded with only if there is no active subscription.
@interface BZRPurchaseHelper : NSObject <BZRPurchaseHelper>

/// Provider that provides the latest receipt validation status.
/// TODO: The weak reference is here to solve a cyclic reference situation. The solution is to
/// extract the receipt validation status to a common state class.
@property (weak, nonatomic) BZRMultiAppReceiptValidationStatusProvider
    *multiAppReceiptValidationStatusProvider;

@end

NS_ASSUME_NONNULL_END
