// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptValidationStatusProvider.h"

@class BZRReceiptDataCache;

@protocol BZRReceiptValidationParametersProvider, BZRReceiptValidator;

NS_ASSUME_NONNULL_BEGIN

/// Provider used to provide a validated \c BZRReceiptValidationStatus.
@interface BZRValidatedReceiptValidationStatusProvider : NSObject
    <BZRReceiptValidationStatusProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c validationParametersProvider, \c receiptDataCache
/// and \c currentApplicationBundleID. \c receiptValidator is set to
/// \c [[BZRValidatricksReceiptValidator alloc] init] wrapped by a \c BZRRetryReceiptValidator.
- (instancetype)initWithValidationParametersProvider:(id<BZRReceiptValidationParametersProvider>)
    validationParametersProvider receiptDataCache:(BZRReceiptDataCache *)receiptDataCache;

/// Initializes \c receiptValidator is used to validate the receipt and return the latest
/// \c BZRReceiptValidationStatus. \c validationParametersProvider is used to provide validation
/// parameters to \c receiptValidator to validate the receipt. \c receiptDataCache is used to store
/// the receipt validation status when validation is requested.
- (instancetype)initWithReceiptValidator:(id<BZRReceiptValidator>)receiptValidator
    validationParametersProvider:(id<BZRReceiptValidationParametersProvider>)
    validationParametersProvider receiptDataCache:(BZRReceiptDataCache *)receiptDataCache
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
