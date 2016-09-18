// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptValidationStatusProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRKeychainStorage, BZRReceiptValidationStatus;

/// Provider that provides the receipt validation status using an underlying provider and caches the
/// receipt validation status to storage.
@interface BZRCachedReceiptValidationStatusProvider : NSObject <BZRReceiptValidationStatusProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c keychainStorage, used to pesist receipt validation status, and with
/// \c underlyingProvider, used to fetch the receipt validation status.
- (instancetype)initWithKeychainStorage:(BZRKeychainStorage *)keychainStorage
                     underlyingProvider:(id<BZRReceiptValidationStatusProvider>)underlyingProvider
    NS_DESIGNATED_INITIALIZER;

/// Holds the most recent receipt validation status that was fetched successfully. If
/// \c fetchReceiptValidationStatus has never completed successfully, this holds the value loaded
/// using \c keychainStorage. If the value doesn't exist in storage, this property will be \c nil.
/// KVO compliant.
@property (readonly, nonatomic, nullable) BZRReceiptValidationStatus *receiptValidationStatus;

@end

NS_ASSUME_NONNULL_END
