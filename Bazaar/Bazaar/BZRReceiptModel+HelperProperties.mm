// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptModel+HelperProperties.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRReceiptSubscriptionInfo (HelperProperties)

- (NSDate *)effectiveExpirationDate {
  if (!self.cancellationDateTime) {
    return self.expirationDateTime;
  }

  return [self.expirationDateTime earlierDate:self.cancellationDateTime];
}

- (BOOL)isActive {
  return !self.isExpired && !self.cancellationDateTime;
}

@end

NS_ASSUME_NONNULL_END
