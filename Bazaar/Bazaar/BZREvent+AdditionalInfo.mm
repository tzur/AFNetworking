// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZREvent+AdditionalInfo.h"

#import "BZRReceiptValidationStatus.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kBZREventReceiptValidationStatusKey = @"BZREventReceiptValidationStatus";
NSString * const kBZREventReceiptValidationRequestIdKey = @"BZREventReceiptValidationRequestId";

@implementation BZREvent (AdditionalInfo)

+ (instancetype)receiptValidationStatusReceivedEvent:
    (BZRReceiptValidationStatus *)receiptValidationStatus
    requestId:(nullable NSString *)requestId {
  return [[BZREvent alloc] initWithType:$(BZREventTypeReceiptValidationStatusReceived)
      eventInfo:@{
        kBZREventReceiptValidationRequestIdKey: requestId,
        kBZREventReceiptValidationStatusKey: receiptValidationStatus
      }];
}

- (nullable BZRReceiptValidationStatus *)receiptValidationStatus {
  return self.eventInfo[kBZREventReceiptValidationStatusKey];
}

- (nullable NSString *)receiptValidationRequestId {
  return self.eventInfo[kBZREventReceiptValidationRequestIdKey];
}

@end

NS_ASSUME_NONNULL_END
