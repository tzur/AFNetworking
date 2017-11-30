// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptValidationStatusProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRKeychainStorage, BZRReceiptValidationStatus, BZRReceiptValidationStatusCache;

@protocol BZRTimeProvider;

/// Provider that provides the receipt validation status using an underlying provider and caches the
/// receipt validation status to \c BZRReceiptValidationStatusCache. This class is thread safe.
@interface BZRCachedReceiptValidationStatusProvider : NSObject <BZRReceiptValidationStatusProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c receiptValidationStatusCache, used to persist receipt validation status, and
/// \c timeProvider used to provide the time the receipt was cached, and with
/// \c underlyingProvider, used to fetch the receipt validation status. \c applicationBundleID is an
/// identifier used to store and retrieve receipt validation status from the current application's
/// partition in storage.
- (instancetype)initWithCache:(BZRReceiptValidationStatusCache *)receiptValidationStatusCache
                 timeProvider:(id<BZRTimeProvider>)timeProvider
           underlyingProvider:(id<BZRReceiptValidationStatusProvider>)underlyingProvider
          applicationBundleID:(NSString *)applicationBundleID
    NS_DESIGNATED_INITIALIZER;

/// Expires the subscription of the user. Updates the cache and the \c receiptValidationStatus with
/// an expired validation status, \c lastReceiptValidationDate remains unchanged.
- (void)expireSubscription;

/// Holds the most recent receipt validation status. Before fetching has completed successfully for
/// the first time this property holds the value loaded from cache. If no value exists in the cache
/// or there was an error while loading from cache, this property will be \c nil.
/// KVO compliant. Changes may be delivered on an arbitrary thread.
@property (readonly, nonatomic, nullable) BZRReceiptValidationStatus *receiptValidationStatus;

/// Holds the date of the last receipt validation. \c nil if \c receiptValidationStatus is \c nil.
/// KVO compliant. Changes may be delivered on an arbitrary thread.
@property (readonly, nonatomic, nullable) NSDate *lastReceiptValidationDate;

@end

NS_ASSUME_NONNULL_END
