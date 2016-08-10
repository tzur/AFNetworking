// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "LTProgress+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTProgress (Bazaar)

+ (instancetype)progressWithTotalUnitCount:(NSNumber *)totalUnitCount
                        completedUnitCount:(NSNumber *)completedUnitCount {
  LTParameterAssert([totalUnitCount doubleValue] >= 0, @"Total units count must not be negative");
  LTParameterAssert([completedUnitCount doubleValue] >= 0,
                    @"Completed units count must not be negative");

  double progress = 0;
  if ([totalUnitCount doubleValue] > 0) {
    progress = [completedUnitCount doubleValue] / [totalUnitCount doubleValue];
  }
  return [[LTProgress alloc] initWithProgress:progress];
}

@end

NS_ASSUME_NONNULL_END
