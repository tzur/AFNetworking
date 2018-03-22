// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "LTFakeKeyValuePersistentStorage.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTFakeKeyValuePersistentStorage

- (instancetype)init {
  if (self = [super init]) {
    _storage = [NSMutableDictionary dictionary];
  }
  return self;
}

- (nullable id)objectForKey:(NSString *)key {
  @synchronized (self) {
    return self.storage[key];
  }
}

- (void)setObject:(nullable id)object forKey:(NSString *)key {
  if (!object) {
    [self removeObjectForKey:key];
  } else {
    @synchronized (self) {
      self.storage[key] = object;
    }
  }
}

- (void)removeObjectForKey:(NSString *)key {
  @synchronized (self) {
    [self.storage removeObjectForKey:key];
  }
}

@end

NS_ASSUME_NONNULL_END
