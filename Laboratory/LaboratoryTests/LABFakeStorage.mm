// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "LABFakeStorage.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LABFakeStorage

- (instancetype)init {
  if (self = [super init]) {
    _storage = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)setObject:(nullable id)value forKey:(NSString *)key {
  if (!value) {
    [self.storage removeObjectForKey:key];
  } else {
    self.storage[key] = value;
  }
}

- (nullable id)objectForKey:(NSString *)key {
  return self.storage[key];
}

@end

NS_ASSUME_NONNULL_END
