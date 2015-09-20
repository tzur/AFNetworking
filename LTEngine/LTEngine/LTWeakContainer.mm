// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTWeakContainer.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTWeakContainer

- (instancetype)init {
  return nil;
}

- (instancetype)initWithObject:(nullable id)object {
  if (self = [super init]) {
    _object = object;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
