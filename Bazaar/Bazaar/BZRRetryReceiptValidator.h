// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptValidator.h"

NS_ASSUME_NONNULL_BEGIN

/// Validator that retries validation if it has failed, using exponential back-off algorithm.
@interface BZRRetryReceiptValidator : NSObject <BZRReceiptValidator>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c underlyingValidator, used to validate the receipt with, and with
/// \c initialRetryDelay, specifying the delay between the first and second validation tries.
/// \c numberOfRetries specifies the number of validation tries after the first try. If
/// \c numberOfRetries is \c 0, there will be no retries.
- (instancetype)initWithUnderlyingValidator:(id<BZRReceiptValidator>)underlyingValidator
                          initialRetryDelay:(NSTimeInterval)initialRetryDelay
                            numberOfRetries:(NSUInteger)numberOfRetries
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
