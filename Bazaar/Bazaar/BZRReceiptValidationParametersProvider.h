// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRReceiptValidationParameters;

/// Protocol for providing \c BZRReceiptValidationParameters.
@protocol BZRReceiptValidationParametersProvider <NSObject>

/// Provides the parameters for receipt validation to be used by \c BZRReciptValidator.
- (nullable BZRReceiptValidationParameters *)receiptValidationParameters;

/// AppStore locale. KVO-compliant.
@property (strong, atomic, nullable) NSLocale *appStoreLocale;

@end

/// Default implementation of \c BZRReceiptValidationParametersProvider, provides the parameters
/// provided by \c -[BZRReceiptValidationParameters defaultParametersWithLocale:] with
/// \c appStoreLocale.
@interface BZRReceiptValidationParametersProvider :
    NSObject <BZRReceiptValidationParametersProvider>
@end

NS_ASSUME_NONNULL_END
