// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTFakeAnalytricksEvent.h"

NS_ASSUME_NONNULL_BEGIN

@implementation INTFakeAnalytricksEvent

@synthesize properties = _properties;

- (instancetype)initWithProperties:(NSDictionary<NSString *,id> *)properties {
  if (self = [super init]) {
    _properties = properties;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
