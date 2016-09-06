// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptValidationStatusProvider.h"

@protocol BZRReceiptValidationParametersProvider, BZRReceiptValidator;

NS_ASSUME_NONNULL_BEGIN

/// Provider used to provide a validated \c BZRReceiptValidationStatus.
@interface BZRValidatedReceiptValidationStatusProvider : NSObject
    <BZRReceiptValidationStatusProvider>

/// Initializes with \c receiptValidator set to \c [[BZRValidatricksReceiptValidator alloc] init]
/// and with \c validationParametersProvider set to
/// \c [[BZRReceiptValidationParametersProvider alloc] init].
- (instancetype)init;

/// Initializes \c receiptValidator is used to validate the receipt and return the latest
/// \c BZRReceiptValidationStatus. \c validationParametersProvider is used to provide validation
/// parameters to \c receiptValidator to validate the receipt.
- (instancetype)initWithReceiptValidator:(id<BZRReceiptValidator>)receiptValidator
    validationParametersProvider:(id<BZRReceiptValidationParametersProvider>)
    validationParametersProvider NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
