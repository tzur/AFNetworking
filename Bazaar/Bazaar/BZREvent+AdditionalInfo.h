// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZREvent.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRReceiptValidationStatus;

/// Key in the event info dictionary mapping to a product's identifier.
extern NSString * const BZREventProductIdentifierKey;

/// Adds methods to conveniently create \c BZREvent objects for various types of events.
@interface BZREvent (AdditionalInfo)

/// Creates a \c BZREvent when a receipt validation status is received with the given
/// \c receiptValidationStatus and the given \c requestId.
+ (instancetype)receiptValidationStatusReceivedEvent:
    (BZRReceiptValidationStatus *)receiptValidationStatus
    requestId:(nullable NSString *)requestId;

/// Receipt validation status associated with this event. \c nil if this event is not of
/// \c BZREventTypeReceiptValidationStatusReceived type.
@property (readonly, nonatomic, nullable) BZRReceiptValidationStatus *receiptValidationStatus;

/// Request ID of the receipt validation status that triggered sending the event. \c nil if this
/// event is not of \c BZREventTypeReceiptValidationStatusReceived type, or if the receipt
/// validation status doesn't have a \c requestId.
@property (readonly, nonatomic, nullable) NSString *receiptValidationRequestId;

@end

NS_ASSUME_NONNULL_END
