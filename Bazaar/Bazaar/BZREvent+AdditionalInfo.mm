// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZREvent+AdditionalInfo.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kBZREventRequestIdKey = @"BZREventRequestId";

@implementation BZREvent (AdditionalInfo)

+ (instancetype)receiptValidationStatusReceivedEvent:(nullable NSString *)requestId {
  return [[BZREvent alloc] initWithType:$(BZREventTypeReceiptValidationStatusReceived)
                              eventInfo:@{kBZREventRequestIdKey: requestId}];
}

- (nullable NSString *)requestId {
  return self.eventInfo[kBZREventRequestIdKey];
}

@end

NS_ASSUME_NONNULL_END
