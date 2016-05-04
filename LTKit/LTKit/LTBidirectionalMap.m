// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTBidirectionalMap.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTBidirectionalMap <KeyType: id<NSCopying>, ObjectType> ()

/// Holds mapping of keys to values.
@property (strong, nonatomic) NSMutableDictionary<KeyType, ObjectType> *keysToValues;

/// Holds mapping of values to keys.
@property (strong, nonatomic) NSMapTable<ObjectType, KeyType> *valuesToKeys;

@end

@implementation LTBidirectionalMap

+ (instancetype)map {
  return [[[self class] alloc] init];
}

+ (instancetype)mapWithDictionary:(NSDictionary *)dictionary {
  return [[[self class] alloc] initWithDictionary:dictionary];
}

- (instancetype)init {
  return [self initWithDictionary:[NSMutableDictionary dictionary]];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
  LTParameterAssert(dictionary);
  if (self = [super init]) {
    self.keysToValues = [dictionary mutableCopy];
    self.valuesToKeys = [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory
                                              valueOptions:NSMapTableStrongMemory];
    [self createValuesToKeysMapping];
  }
  return self;
}

- (void)createValuesToKeysMapping {
  [self.keysToValues enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL __unused *stop) {
    [self.valuesToKeys setObject:key forKey:obj];
  }];
}

- (nullable id)objectForKeyedSubscript:(id<NSCopying>)key {
  LTParameterAssert(key);
  return self.keysToValues[key];
}

- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key {
  LTParameterAssert(key && obj);
  LTParameterAssert(![self keyForObject:obj],
                    @"Object must not exist in the map prior to insertion");
  self.keysToValues[key] = obj;
  [self.valuesToKeys setObject:key forKey:obj];
}

- (void)removeObjectForKey:(id<NSCopying>)key {
  LTParameterAssert(key);
  id obj = self.keysToValues[key];
  [self.keysToValues removeObjectForKey:key];
  [self.valuesToKeys removeObjectForKey:obj];
}

- (nullable id)keyForObject:(id)object {
  return [self.valuesToKeys objectForKey:object];
}

- (NSArray *)allKeys {
  return [self.keysToValues allKeys];
}

- (NSArray *)allValues {
  return [self.keysToValues allValues];
}

- (NSUInteger)count {
  return self.keysToValues.count;
}

- (BOOL)isEqual:(id)object {
  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:[LTBidirectionalMap class]]) {
    return NO;
  }

  return [self.keysToValues isEqual:((LTBidirectionalMap *)object).keysToValues];
}

- (NSString *)description {
  return [self.keysToValues description];
}

@end

NS_ASSUME_NONNULL_END
