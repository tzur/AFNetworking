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

/// Initializes with \c receiptValidator set to \c [[BZRValidatricksReceiptValidator alloc] init]
/// and with \c validationParametersProvider.
- (instancetype)initWithValidationParametersProvider:(id<BZRReceiptValidationParametersProvider>)
    validationParametersProvider receiptDataCache:(BZRReceiptDataCache *)receiptDataCache
    currentApplicationBundleID:(NSString *)currentApplicationBundleID;

/// Initializes \c receiptValidator is used to validate the receipt and return the latest
/// \c BZRReceiptValidationStatus. \c validationParametersProvider is used to provide validation
/// parameters to \c receiptValidator to validate the receipt. \c receiptDataCache is used to store
/// the receipt validation status when validation is requested. \c currentApplicationBundleID is
/// used to store the receipt data to the storage of the current application.
- (instancetype)initWithReceiptValidator:(id<BZRReceiptValidator>)receiptValidator
    validationParametersProvider:(id<BZRReceiptValidationParametersProvider>)
    validationParametersProvider receiptDataCache:(BZRReceiptDataCache *)receiptDataCache
    currentApplicationBundleID:(NSString *)currentApplicationBundleID
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
