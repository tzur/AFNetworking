// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRModel.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRReceiptInfo, BZRReceiptValidationError;

/// Value object that represents a receipt-validation status.
@interface BZRReceiptValidationStatus : BZRModel <MTLJSONSerializing, NSSecureCoding>

/// \c YES if the receipt was validated successfully and is found to be valid. If this is \c NO then
/// \c error will provide information on the reason for validation failure.
@property (readonly, nonatomic) BOOL isValid;

/// In case validation has failed \c error will describe the reason for the failure. If validation
/// succeeded with no errors then this will be \c nil.
@property (readonly, nonatomic, nullable) BZRReceiptValidationError *error;

/// Date and time of the validation.
@property (readonly, nonatomic) NSDate *validationDateTime;

/// Information extracted from the receipt sent for validation or \c nil if validation failed.
@property (readonly, nonatomic, nullable) BZRReceiptInfo *receipt;

/// Unique identifier of the receipt validation request.
@property (readonly, nonatomic) NSString *requestId;

@end

NS_ASSUME_NONNULL_END
