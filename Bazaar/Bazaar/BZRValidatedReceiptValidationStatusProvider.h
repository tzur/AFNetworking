// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptValidationStatusProvider.h"

@class BZRReceiptDataCache;

@protocol BZRReceiptValidationParametersProvider, BZRValidatricksClient, BZRUserIDProvider;

NS_ASSUME_NONNULL_BEGIN

/// Provider used to provide a validated \c BZRReceiptValidationStatus.
@interface BZRValidatedReceiptValidationStatusProvider : NSObject
    <BZRReceiptValidationStatusProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c validatricksClient is used to validate the receipt and return the latest
/// \c BZRReceiptValidationStatus. \c validationParametersProvider is used to provide validation
/// parameters to \c validatricksClient to validate the receipt. \c receiptDataCache is used to
/// store the receipt validation status when validation is requested. \c userIDProvider is used to
/// get a unique identifier of the user to send to validation.
- (instancetype)initWithValidatricksClient:(id<BZRValidatricksClient>)validatricksClient
    validationParametersProvider:(id<BZRReceiptValidationParametersProvider>)
    validationParametersProvider
    receiptDataCache:(BZRReceiptDataCache *)receiptDataCache
    userIDProvider:(id<BZRUserIDProvider>)userIDProvider
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
