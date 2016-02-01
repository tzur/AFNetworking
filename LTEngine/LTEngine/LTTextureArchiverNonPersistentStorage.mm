// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureArchiverNonPersistentStorage.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTTextureArchiverNonPersistentStorage ()

/// Dictionary used for storing the values.
@property (strong, nonatomic) NSMutableDictionary *mutableDictionary;

@end

@implementation LTTextureArchiverNonPersistentStorage

- (instancetype)init {
  if (self = [super init]) {
    self.mutableDictionary = [NSMutableDictionary dictionary];
  }
  return self;
}

- (nullable id)objectForKeyedSubscript:(NSString *)key {
  return self.mutableDictionary[key];
}

- (void)setObject:(id<NSCopying>)object forKeyedSubscript:(NSString *)key {
  self.mutableDictionary[key] = object;
}

- (void)removeObjectForKey:(NSString *)key {
  [self.mutableDictionary removeObjectForKey:key];
}

- (NSArray *)allKeys {
  return [self.mutableDictionary allKeys];
}

@end

/// Category exposing the dictionary behind the non persistent storage, for testing purposes.
@interface LTTextureArchiverNonPersistentStorage (ForTesting)

/// Returns a dictionary representation of the storage.
@property (readonly, nonatomic) NSDictionary *dictionary;

@end

@implementation LTTextureArchiverNonPersistentStorage (ForTesting)

- (NSDictionary *)dictionary {
  return [self.mutableDictionary copy];
}

@end

NS_ASSUME_NONNULL_END
