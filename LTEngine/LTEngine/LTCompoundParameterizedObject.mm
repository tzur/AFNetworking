// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTCompoundParameterizedObject.h"

#import "LTPrimitiveParameterizedObject.h"

NS_ASSUME_NONNULL_BEGIN

/// Represents mutable mapping from key to boxed \c CGFloat returned by parameterized objects.
typedef NSMutableDictionary<NSString *, NSNumber *> LTMutableParameterizationKeyToValue;

/// Represents mutable mapping from key to ordered collection of boxed \c CGFloat returned by
/// parameterized objects.
typedef NSMutableDictionary<NSString *, NSArray<NSNumber *> *> LTMutableParameterizationKeyToValues;

@interface LTCompoundParameterizedObject ()

/// Mapping of keys to their corresponding primitive parameterized objects.
@property (strong, readwrite, nonatomic) LTKeyToPrimitiveParameterizedObject *mapping;

/// See \c LTParameterizedObject protocol.
@property (strong, nonatomic) NSSet<NSString *> *parameterizationKeys;

/// See \c LTParameterizedObject protocol.
@property (nonatomic) CGFloat minParametricValue;

/// See \c LTParameterizedObject protocol.
@property (nonatomic) CGFloat maxParametricValue;

@end

@implementation LTCompoundParameterizedObject

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithMapping:(LTKeyToPrimitiveParameterizedObject *)mapping {
  if (self = [super init]) {
    [self validateMapping:mapping];
    self.mapping = [mapping copy];
    self.parameterizationKeys = [NSSet setWithArray:[mapping allKeys]];
    id<LTPrimitiveParameterizedObject> object = mapping[[mapping allKeys].firstObject];
    self.minParametricValue = object.minParametricValue;
    self.maxParametricValue = object.maxParametricValue;
  }
  return self;
}

- (void)validateMapping:(LTKeyToPrimitiveParameterizedObject *)mapping {
  NSString *keyOfFirstObject = mapping.allKeys.firstObject;
  LTParameterAssert(keyOfFirstObject, @"The given mapping must have at least one key");
  id<LTPrimitiveParameterizedObject> firstObject = mapping[keyOfFirstObject];
  [mapping enumerateKeysAndObjectsUsingBlock:^(NSString *key,
                                               id<LTPrimitiveParameterizedObject> object, BOOL *) {
    LTParameterAssert(object.minParametricValue == firstObject.minParametricValue &&
                      object.maxParametricValue == firstObject.maxParametricValue,
                      @"Intrinsic parametric ranges [%f, %f] of object with key (%@) doesn't match "
                      "range [%f, %f] of object with key (%@)", object.minParametricValue,
                      object.maxParametricValue, key, firstObject.minParametricValue,
                      firstObject.maxParametricValue, keyOfFirstObject);
  }];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(LTCompoundParameterizedObject *)object {
  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:[self class]]) {
    return NO;
  }

  return [self.mapping isEqualToDictionary:object.mapping];
}

- (NSUInteger)hash {
  return self.mapping.hash;
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (id)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

#pragma mark -
#pragma mark LTParameterizedObject
#pragma mark -

- (LTParameterizationKeyToValue *)mappingForParametricValue:(CGFloat)value {
  LTMutableParameterizationKeyToValue *result =
      [LTMutableParameterizationKeyToValue dictionaryWithCapacity:self.parameterizationKeys.count];
  for (NSString *key in self.parameterizationKeys) {
    result[key] = @([self.mapping[key] floatForParametricValue:value]);
  }
  return [result copy];
}

- (LTParameterizationKeyToValues *)mappingForParametricValues:(const CGFloats &)values {
  LTMutableParameterizationKeyToValues *result =
      [LTMutableParameterizationKeyToValues dictionaryWithCapacity:self.parameterizationKeys.count];
  for (NSString *key in self.parameterizationKeys) {
    NSMutableArray<NSNumber *> *boxedValues = [NSMutableArray arrayWithCapacity:values.size()];
    id<LTPrimitiveParameterizedObject> object = [self primitiveParameterizedObjectForKey:key];
    for (const CGFloat &value : values) {
      [boxedValues addObject:@([object floatForParametricValue:value])];
    }
    result[key] = boxedValues;
  }
  return [result copy];
}

- (CGFloat)floatForParametricValue:(CGFloat)value key:(NSString *)key {
  id<LTPrimitiveParameterizedObject> object = [self primitiveParameterizedObjectForKey:key];
  return [object floatForParametricValue:value];
}

- (CGFloats)floatsForParametricValues:(const CGFloats &)values key:(NSString *)key {
  id<LTPrimitiveParameterizedObject> object = [self primitiveParameterizedObjectForKey:key];
  CGFloats result(values.size());
  std::transform(values.begin(), values.end(), result.begin(), [object](const CGFloat &value) {
    return [object floatForParametricValue:value];
  });
  return result;
}

#pragma mark -
#pragma mark Auxiliary methods
#pragma mark -

- (id<LTPrimitiveParameterizedObject>)primitiveParameterizedObjectForKey:(NSString *)key {
  id<LTPrimitiveParameterizedObject> result = self.mapping[key];
  LTParameterAssert(result,
                    @"No primitive parameterized object specified for given key: \"%@\"", key);
  return result;
}

@end

NS_ASSUME_NONNULL_END
