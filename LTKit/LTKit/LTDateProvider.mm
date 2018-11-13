// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "LTDateProvider.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTDateProvider

+ (id<LTDateProvider>)dateProvider {
  return [[LTDateProvider alloc] init];
}

- (NSDate *)currentDate {
  return [NSDate date];
}

@end

NS_ASSUME_NONNULL_END
