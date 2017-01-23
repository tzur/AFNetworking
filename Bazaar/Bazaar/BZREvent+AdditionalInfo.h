// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZREvent.h"

NS_ASSUME_NONNULL_BEGIN

/// Adds methods to conveniently create BZREvents and certain properties.
@interface BZREvent (AdditionalInfo)

/// Creates a \c BZREvent when a receipt validation status is received with the given \c requestId.
+ (instancetype)receiptValidationStatusReceivedEvent:(nullable NSString *)requestId;

/// Request ID of the receipt validation status that triggered sending the receiver. \c nil if this
/// event is not of \c BZREventTypeReceiptValidationStatusReceived type, or if the receipt
/// validation status doesn't have \c requestId.
@property (readonly, nonatomic, nullable) NSString *requestId;

@end

NS_ASSUME_NONNULL_END
