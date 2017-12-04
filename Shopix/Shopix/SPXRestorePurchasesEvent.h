// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import <LTKit/LTValueObject.h>

NS_ASSUME_NONNULL_BEGIN

@class BZRReceiptInfo;

/// Represents the event where the user attempted to restore previous purchases.
@interface SPXRestorePurchasesEvent : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c successfulRestore describing if the restore was successful,
/// \c receiptSubscriptionInfo the receipt information received after the restoration and
/// \c restoreDuration the duration of the restore process and \c error with an appropriate error on
/// failure.
- (instancetype)initWithSuccessfulRestore:(BOOL)successfulRestore
                              receiptInfo:(nullable BZRReceiptInfo *)receiptInfo
                          restoreDuration:(CFTimeInterval)restoreDuration
                                    error:(nullable NSError *)error NS_DESIGNATED_INITIALIZER;

/// \c YES if the restore was successful, \c NO otherwise.
@property (readonly, nonatomic) BOOL successfulRestore;

/// /c YES if the user has an active subscription after the restoration, \c NO otherwise.
@property (readonly, nonatomic) BOOL isSubscriber;

/// ID of the transaction in which the user has purchased the subscription.
@property (readonly, nonatomic, nullable) NSString *originalTransactionId;

/// Duration of the restore process.
@property (readonly, nonatomic) CFTimeInterval restoreDuration;

/// Failure description if the restoration was unsuccessful, \c nil otherwise.
@property (readonly, nonatomic, nullable) NSString *failureDescription;

@end

NS_ASSUME_NONNULL_END
