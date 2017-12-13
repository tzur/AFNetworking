// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptValidationStatusProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRKeychainStorage, BZRReceiptValidationStatus, BZRReceiptValidationStatusCache,
    BZRReceiptValidationStatusCacheEntry;

@protocol BZRTimeProvider;

/// Provider that provides the receipt validation status using an underlying provider and caches the
/// receipt validation status to \c BZRReceiptValidationStatusCache. This class is thread safe.
@interface BZRCachedReceiptValidationStatusProvider : NSObject <BZRReceiptValidationStatusProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c receiptValidationStatusCache, \c timeProvider,
/// \c applicationBundleID, and \c cachedEntryTimeToLive set to \c 14.
- (instancetype)initWithCache:(BZRReceiptValidationStatusCache *)receiptValidationStatusCache
                 timeProvider:(id<BZRTimeProvider>)timeProvider
           underlyingProvider:(id<BZRReceiptValidationStatusProvider>)underlyingProvider
          applicationBundleID:(NSString *)applicationBundleID;

/// Initializes with \c receiptValidationStatusCache, used to persist receipt validation status, and
/// \c timeProvider used to provide the time the receipt was cached, and with
/// \c underlyingProvider, used to fetch the receipt validation status. \c applicationBundleID is an
/// identifier used to store and retrieve receipt validation status from the current application's
/// partition in storage. \c cachedEntryDaysToLive is the number of days cache entries are valid
/// for. Cache entries older than that will be invalidated and remain invalid until a successful
/// receipt validation.
- (instancetype)initWithCache:(BZRReceiptValidationStatusCache *)receiptValidationStatusCache
                 timeProvider:(id<BZRTimeProvider>)timeProvider
           underlyingProvider:(id<BZRReceiptValidationStatusProvider>)underlyingProvider
          applicationBundleID:(NSString *)applicationBundleID
        cachedEntryDaysToLive:(NSUInteger)cachedEntryDaysToLive NS_DESIGNATED_INITIALIZER;

/// Loads receipt validation status cache entry of the application specified by
/// \c applicationBundleID. If the cache entry couldn't be found or there was an error \c nil will
/// be returned.
- (nullable BZRReceiptValidationStatusCacheEntry *)loadReceiptValidationStatusCacheEntryFromStorage:
    (NSString *)applicationBundleID;

/// Holds the most recent receipt validation status. Before fetching has completed successfully for
/// the first time this property holds the value loaded from cache. If no value exists in the cache
/// or there was an error while loading from cache, this property will be \c nil.
/// KVO compliant. Changes may be delivered on an arbitrary thread.
@property (readonly, nonatomic, nullable) BZRReceiptValidationStatus *receiptValidationStatus;

/// Holds the date of the last receipt validation. \c nil if \c receiptValidationStatus is \c nil.
/// KVO compliant. Changes may be delivered on an arbitrary thread.
@property (readonly, nonatomic, nullable) NSDate *lastReceiptValidationDate;

@end

#pragma mark -
#pragma mark BZRCachedReceiptValidationStatusProvider+MultiApp
#pragma mark -

/// Maps product application bundle ID to receipt validation status.
typedef NSDictionary<NSString *, BZRReceiptValidationStatus *> BZRMultiAppReceiptValidationStatus;

/// Adds convenience methods for fetching and loading receipt validation status of multiple
/// applications.
@interface BZRCachedReceiptValidationStatusProvider (MultiApp)

/// Fetches receipt validation status of the applications specified by \c bundledApplicationsIDs.
///
/// Returns a signal that sends a dictionary mapping bundle ID to its corresponding receipt
/// validation status. Then the signal completes. If there was an error fetching a receipt
/// validation status, its bundleID will not appear in the dictionary sent, but rather the error
/// will be sent on \c eventsSignal. The signal errs if all the validations failed with error code
/// \c BZRErrorCodeReceiptValidationFailed and validation errors in the \c NSError's
/// \c lt_underlyingErrors.
- (RACSignal<BZRMultiAppReceiptValidationStatus *> *)fetchReceiptValidationStatuses:
    (NSSet<NSString *> *)bundledApplicationsIDs;

/// Loads the cache entry of the applications specified by \c bundledApplicationsIDs. If there was
/// an error loading a cache cache entry or it was not found in cache, it will not appear in the
/// returned dictionary.
- (NSDictionary<NSString *, BZRReceiptValidationStatusCacheEntry *> *)
    loadReceiptValidationStatusCacheEntries:(NSSet<NSString *> *)bundledApplicationsIDs;

@end

NS_ASSUME_NONNULL_END
