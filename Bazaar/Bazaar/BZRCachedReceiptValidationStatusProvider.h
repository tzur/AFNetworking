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

/// Initializes with \c receiptValidationStatusCache, used to persist receipt validation status, and
/// \c timeProvider used to provide the time the receipt was cached, and with
/// \c underlyingProvider, used to fetch the receipt validation status. \c cachedEntryDaysToLive is
/// the number of days cache entries are valid for. Cache entries older than that will be
/// invalidated and remain invalid until a successful receipt validation.
- (instancetype)initWithCache:(BZRReceiptValidationStatusCache *)receiptValidationStatusCache
                 timeProvider:(id<BZRTimeProvider>)timeProvider
           underlyingProvider:(id<BZRReceiptValidationStatusProvider>)underlyingProvider
        cachedEntryDaysToLive:(NSUInteger)cachedEntryDaysToLive NS_DESIGNATED_INITIALIZER;

/// Cache used to store and load receipt validation status cache entries.
@property (readonly, nonatomic) BZRReceiptValidationStatusCache *cache;

@end

#pragma mark -
#pragma mark BZRCachedReceiptValidationStatusProvider+MultiApp
#pragma mark -

/// Maps product application bundle ID to receipt validation status.
typedef NSDictionary<NSString *, BZRReceiptValidationStatus *> BZRMultiAppReceiptValidationStatus;

/// Adds convenience methods for fetching receipt validation statuses of multiple applications.
@interface BZRCachedReceiptValidationStatusProvider (MultiApp)

/// Fetches receipt validation status of the applications specified by \c bundledApplicationsIDs.
///
/// Returns a signal that sends a dictionary mapping bundle ID to its corresponding receipt
/// validation status. Then the signal completes. If there was an error fetching a receipt
/// validation status, its value will be taken from cache. If it was not found in cache, its value
/// will not appear in the dictionary sent. Every validation error will be sent on \c eventsSignal.
/// The signal errs if all the validations failed with error code
/// \c BZRErrorCodeReceiptValidationFailed and validation errors in the \c NSError's
/// \c lt_underlyingErrors.
- (RACSignal<BZRMultiAppReceiptValidationStatus *> *)fetchReceiptValidationStatuses:
    (NSSet<NSString *> *)bundledApplicationsIDs;

@end

NS_ASSUME_NONNULL_END
