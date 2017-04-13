// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptValidationStatusProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRKeychainStorage, BZRReceiptValidationStatus, BZRKeychainStorageMigrator;

@protocol BZRTimeProvider;

/// Provider that provides the receipt validation status using an underlying provider and caches the
/// receipt validation status to storage. This class is thread safe.
@interface BZRCachedReceiptValidationStatusProvider : NSObject <BZRReceiptValidationStatusProvider>

/// Copies the receipt validation status from source storage to target storage that specefied in
/// \c migrator. Returns \c YES in a case of successful migration or if the target storage is
/// already holding receipt validation status, otherwise returns \c NO and \c error is set with an
/// appropriate error.
+ (BOOL)migrateReceiptValidationStatusWithMigrator:(BZRKeychainStorageMigrator *)migrator
                                             error:(NSError **)error;

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c keychainStorage, used to pesist receipt validation status, with
/// \c timeProvider used to persist the time the receipt was validated, and with
/// \c underlyingProvider, used to fetch the receipt validation status.
- (instancetype)initWithKeychainStorage:(BZRKeychainStorage *)keychainStorage
                           timeProvider:(id<BZRTimeProvider>)timeProvider
                     underlyingProvider:(id<BZRReceiptValidationStatusProvider>)underlyingProvider
    NS_DESIGNATED_INITIALIZER;

/// Loads the receipt validation status from storage and saves it to \c receiptValidationStatus.
/// In addition, the last receipt validation date is loaded from storage and saved to
/// \c lastReceiptValidationDate. If an error occurred while loading from cache,
/// \c receiptValidationStatus is not modified, \c error is populated with error information and
/// \c nil is returned.
/// Returns the loaded \c receiptValidationStatus or \c nil if no validation status is stored in the
/// cache.
- (nullable BZRReceiptValidationStatus *)refreshReceiptValidationStatus:(NSError **)error;

/// Expires the subscription of the user.
- (void)expireSubscription;

/// Holds the most recent receipt validation status that was fetched successfully. If
/// \c fetchReceiptValidationStatus has never completed successfully, this holds the value loaded
/// using \c keychainStorage. If the value doesn't exist in storage, this property will be \c nil.
/// KVO compliant. Changes may be delivered on an arbitrary thread.
@property (readonly, nonatomic, nullable) BZRReceiptValidationStatus *receiptValidationStatus;

/// Holds the date of the last receipt validation. \c nil if \c receiptValidationStatus is \c nil.
/// KVO compliant. Changes may be delivered on an arbitrary thread.
@property (readonly, nonatomic, nullable) NSDate *lastReceiptValidationDate;

@end

NS_ASSUME_NONNULL_END
