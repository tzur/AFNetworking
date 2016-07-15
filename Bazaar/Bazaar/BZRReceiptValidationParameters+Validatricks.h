// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptValidationParameters.h"

NS_ASSUME_NONNULL_BEGIN

/// Adds some convenience methods for creating a Validatricks validation request from a
/// \c BZRReceiptValidationParameters model.
@interface BZRReceiptValidationParameters (Validatricks)

/// Returns an \c NSDictionary in the format defined by the Validatricks API that can be used as
/// receipt validation requests send to a Validatricks server.
- (NSDictionary<NSString *, NSString *> *)validatricksRequestParameters;

@end

NS_ASSUME_NONNULL_END
