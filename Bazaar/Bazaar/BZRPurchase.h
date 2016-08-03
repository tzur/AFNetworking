// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Hagai Weinfeld.

NS_ASSUME_NONNULL_BEGIN

/// Block used to deliver \c SKPaymentTransaction updates.
typedef void (^BZRTransactionUpdateBlock)(SKPaymentTransaction *transaction);

/// Value class representing a unique purchase in a payment queue.
@interface BZRPurchase : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initialize with \c payment, \c updateBlock. \c updateBlock should be called with
/// \c SKPaymentTransaction updates for \c payment.
- (instancetype)initWithPayment:(SKPayment *)payment
                    updateBlock:(BZRTransactionUpdateBlock)updateBlock;

/// Payment represented by this \c BZRPurchase.
@property (readonly, nonatomic) SKPayment *payment;

/// Block to which updates regarding this \c payment should be delivered.
@property (readonly, nonatomic) BZRTransactionUpdateBlock updateBlock;

@end

NS_ASSUME_NONNULL_END
