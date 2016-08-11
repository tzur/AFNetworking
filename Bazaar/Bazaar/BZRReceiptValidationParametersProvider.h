// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRReceiptValidationParameters;

/// Protocol for providing \c BZRReceiptValidationParameters.
@protocol BZRReceiptValidationParametersProvider <NSObject>

/// Provides the parameters for receipt validation to be used by \c BZRReciptValidator.
- (nullable BZRReceiptValidationParameters *)receiptValidationParameters;

@end

/// Default implementation of \c BZRReceiptValidationParametersProvider, provides the parameters
/// provided by \c -[BZRReceiptValidationParameters defaultParameters].
@interface BZRReceiptValidationParametersProvider :
    NSObject <BZRReceiptValidationParametersProvider>
@end

NS_ASSUME_NONNULL_END
