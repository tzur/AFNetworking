// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTCompoundParameterizedObject.h"

#import "LTParameterizationKeyToValues.h"
#import "LTBasicParameterizedObject.h"

NS_ASSUME_NONNULL_BEGIN

/// Represents mutable mapping from key to boxed \c CGFloat returned by parameterized objects.
typedef NSMutableDictionary<NSString *, NSNumber *> LTMutableParameterizationKeyToValue;

@interface LTCompoundParameterizedObject ()

/// Mapping of keys to their corresponding basic parameterized objects.
@property (strong, readwrite, nonatomic) LTKeyToBaseParameterizedObject *mapping;

/// See \c LTParameterizedObject protocol.
@property (strong, nonatomic) NSSet<NSString *> *parameterizationKeys;

/// Ordered set of parameterization keys.
@property (strong, nonatomic) NSOrderedSet<NSString *> *orderedParameterizationKeys;

/// See \c LTParameterizedObject protocol.
@property (nonatomic) CGFloat minParametricValue;

/// See \c LTParameterizedObject protocol.
@property (nonatomic) CGFloat maxParametricValue;

@end

@implementation LTCompoundParameterizedObject

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithMapping:(LTKeyToBaseParameterizedObject *)mapping {
  LTParameterAssert([mapping allKeys].count <= INT_MAX,
                    @"Number (%lu) of keys must not exceed INT_MAX",
                    (unsigned long)[mapping allKeys].count);

  if (self = [super init]) {
    [self validateMapping:mapping];
    self.mapping = [mapping copy];
    self.parameterizationKeys = [NSSet setWithArray:[mapping allKeys]];
    self.orderedParameterizationKeys = [NSOrderedSet orderedSetWithSet:self.parameterizationKeys];
    id<LTBasicParameterizedObject> object = mapping[[mapping allKeys].firstObject];
    self.minParametricValue = object.minParametricValue;
    self.maxParametricValue = object.maxParametricValue;
  }
  return self;
}

- (void)validateMapping:(LTKeyToBaseParameterizedObject *)mapping {
  NSString *keyOfFirstObject = mapping.allKeys.firstObject;
  LTParameterAssert(keyOfFirstObject, @"The given mapping must have at least one key");
  id<LTBasicParameterizedObject> firstObject = mapping[keyOfFirstObject];
  [mapping enumerateKeysAndObjectsUsingBlock:^(NSString *key, id<LTBasicParameterizedObject> object,
                                               BOOL *) {
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

- (LTParameterizationKeyToValues *)mappingForParametricValues:(const CGFloats &)parametricValues {
  LTParameterAssert(parametricValues.size() <= INT_MAX,
                    @"Number (%lu) of parametric values must not exceed INT_MAX",
                    (unsigned long)parametricValues.size());
  __block cv::Mat1g valuesPerKey((int)self.orderedParameterizationKeys.count,
                                 (int)parametricValues.size());

  [self.orderedParameterizationKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger i,
                                                                 BOOL *) {
    id<LTBasicParameterizedObject> object = [self baseParameterizedObjectForKey:key];
    for (int j = 0; j < (int)parametricValues.size(); ++j) {
      valuesPerKey((int)i, j) = (float)[object floatForParametricValue:parametricValues[j]];
    }
  }];

  return [[LTParameterizationKeyToValues alloc] initWithKeys:self.orderedParameterizationKeys
                                                valuesPerKey:valuesPerKey];
}

- (CGFloat)floatForParametricValue:(CGFloat)value key:(NSString *)key {
  id<LTBasicParameterizedObject> object = [self baseParameterizedObjectForKey:key];
  return [object floatForParametricValue:value];
}

- (CGFloats)floatsForParametricValues:(const CGFloats &)values key:(NSString *)key {
  id<LTBasicParameterizedObject> object = [self baseParameterizedObjectForKey:key];
  CGFloats result(values.size());
  std::transform(values.begin(), values.end(), result.begin(), [object](const CGFloat &value) {
    return [object floatForParametricValue:value];
  });
  return result;
}

#pragma mark -
#pragma mark Auxiliary methods
#pragma mark -

- (id<LTBasicParameterizedObject>)baseParameterizedObjectForKey:(NSString *)key {
  id<LTBasicParameterizedObject> result = self.mapping[key];
  LTParameterAssert(result,
                    @"No basic parameterized object specified for given key: \"%@\"", key);
  return result;
}

@end

NS_ASSUME_NONNULL_END
