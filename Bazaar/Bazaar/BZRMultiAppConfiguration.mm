// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRMultiAppConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRMultiAppConfiguration

- (instancetype)initWithBundledApplicationsIDs:(NSSet<NSString *> *)bundledApplicationsIDs
          multiAppSubscriptionIdentifierMarker:(NSString *)multiAppSubscriptionIdentifierMarker {
  if (self = [super init]) {
    _bundledApplicationsIDs = [bundledApplicationsIDs copy];
    _multiAppSubscriptionIdentifierMarker = [multiAppSubscriptionIdentifierMarker copy];
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
