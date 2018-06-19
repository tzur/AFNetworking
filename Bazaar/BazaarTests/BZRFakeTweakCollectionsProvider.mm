// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRFakeTweakCollectionsProvider.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRFakeTweakCollectionsProvider

- (instancetype)init {
  if (self = [super init]) {
    _collections = @[];
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
