// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZREventEmitter.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRKeychainStorage, BZRReceiptValidationParameters;

/// Protocol for providing \c BZRReceiptValidationParameters.
@protocol BZRReceiptValidationParametersProvider <BZREventEmitter>

/// Provides the parameters for receipt validation to be used by \c BZRReciptValidator.
- (nullable BZRReceiptValidationParameters *)receiptValidationParameters;

/// AppStore locale. KVO-compliant.
@property (strong, atomic, nullable) NSLocale *appStoreLocale;

@end

/// Default implementation of \c BZRReceiptValidationParametersProvider, provides the parameters
/// provided by \c -[BZRReceiptValidationParameters defaultParametersWithLocale:] with
/// \c appStoreLocale. If \c appStoreLocale is \c nil, \c receiptValidationParameters will return
/// \c nil.
@interface BZRReceiptValidationParametersProvider :
    NSObject <BZRReceiptValidationParametersProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c keychainStorage, used to store and load App Store locale.
- (instancetype)initWithKeychainStorage:(BZRKeychainStorage *)keychainStorage;

@end

NS_ASSUME_NONNULL_END
