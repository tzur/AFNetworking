// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "NSValueTransformer+Bazaar.h"

#import <Mantle/MTLValueTransformer.h>

NS_ASSUME_NONNULL_BEGIN

@implementation NSValueTransformer (Bazaar)

+ (NSValueTransformer *)bzr_timeIntervalSince1970ValueTransformer {
  return [MTLValueTransformer reversibleTransformerWithForwardBlock:
          ^NSDate * _Nullable(NSNumber * _Nullable timeInterval) {
            return timeInterval ?
                [NSDate dateWithTimeIntervalSince1970:[timeInterval doubleValue]] : nil;
          } reverseBlock:^NSNumber * _Nullable(NSDate * _Nullable dateTime) {
            return dateTime ? @(dateTime.timeIntervalSince1970) : nil;
          }];
}

@end

NS_ASSUME_NONNULL_END
