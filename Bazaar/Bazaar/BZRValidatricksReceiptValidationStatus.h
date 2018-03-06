// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptValidationStatus.h"

NS_ASSUME_NONNULL_BEGIN

/// Value object that represents a receipt-validation status received from Validatricks.
@interface BZRValidatricksReceiptValidationStatus : BZRReceiptValidationStatus

/// Unique identifier of the receipt validation request.
@property (readonly, nonatomic) NSString *requestId;

@end

NS_ASSUME_NONNULL_END
