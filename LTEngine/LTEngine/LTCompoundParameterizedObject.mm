// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTCompoundParameterizedObject.h"

#import <LTKit/NSArray+Functional.h>

#import "LTBasicParameterizedObject.h"
#import "LTParameterizationKeyToValues.h"

NS_ASSUME_NONNULL_BEGIN

/// Represents mutable mapping from key to boxed \c CGFloat returned by parameterized objects.
typedef NSMutableDictionary<NSString *, NSNumber *> LTMutableParameterizationKeyToValue;

#pragma mark -
#pragma mark LTKeyBasicParameterizedObjectPair
#pragma mark -

@interface LTKeyBasicParameterizedObjectPair ()

/// Initializes with the given \c key and the given \c basicParameterizedObject.
- (instancetype)initWithKey:(NSString *)key
   basicParameterizedObject:(id<LTBasicParameterizedObject>)basicParameterizedObject;

@end

@implementation LTKeyBasicParameterizedObjectPair

- (instancetype)initWithKey:(NSString *)key
   basicParameterizedObject:(id<LTBasicParameterizedObject>)basicParameterizedObject {
  if (self = [super init]) {
    _key = key;
    _basicParameterizedObject = basicParameterizedObject;
  }
  return self;
}

+ (instancetype)pairWithKey:(NSString *)key
   basicParameterizedObject:(id<LTBasicParameterizedObject>)basicParameterizedObject {
  return [[self alloc] initWithKey:key basicParameterizedObject:basicParameterizedObject];
}

@end

#pragma mark -
#pragma mark LTCompoundParameterizedObject
#pragma mark -

@implementation LTCompoundParameterizedObject

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithMapping:(LTKeyToBaseParameterizedObject *)mapping {
  LTParameterAssert(mapping.count <= INT_MAX, @"Number (%lu) of keys must not exceed INT_MAX",
                    (unsigned long)mapping.count);

  if (self = [super init]) {
    _mapping = mapping;
    _parameterizationKeys = [self parameterizationKeysFromValidatedMapping:mapping];
    id<LTBasicParameterizedObject> object = mapping.firstObject.basicParameterizedObject;
    _minParametricValue = object.minParametricValue;
    _maxParametricValue = object.maxParametricValue;
  }
  return self;
}

- (NSOrderedSet<NSString *> *)
    parameterizationKeysFromValidatedMapping:(LTKeyToBaseParameterizedObject *)mapping {
  NSString *keyOfFirstObject = mapping.firstObject.key;
  LTParameterAssert(keyOfFirstObject, @"The given mapping must have at least one key");
  id<LTBasicParameterizedObject> firstObject = mapping.firstObject.basicParameterizedObject;

  NSMutableOrderedSet *parameterizationKeys =
      [NSMutableOrderedSet orderedSetWithCapacity:mapping.count];

  for (LTKeyBasicParameterizedObjectPair *pair in mapping) {
    NSString *key = pair.key;
    [parameterizationKeys addObject:key];
    id<LTBasicParameterizedObject> object = pair.basicParameterizedObject;
    LTParameterAssert(object.minParametricValue == firstObject.minParametricValue &&
                      object.maxParametricValue == firstObject.maxParametricValue,
                      @"Intrinsic parametric ranges [%f, %f] of object with key (%@) doesn't match "
                      "range [%f, %f] of object with key (%@)", object.minParametricValue,
                      object.maxParametricValue, key, firstObject.minParametricValue,
                      firstObject.maxParametricValue, keyOfFirstObject);
  }

  return parameterizationKeys;
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

  return [self.mapping isEqualToArray:object.mapping];
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

@synthesize parameterizationKeys = _parameterizationKeys;
@synthesize minParametricValue = _minParametricValue;
@synthesize maxParametricValue = _maxParametricValue;

- (LTParameterizationKeyToValue *)mappingForParametricValue:(CGFloat)value {
  LTMutableParameterizationKeyToValue *result =
      [LTMutableParameterizationKeyToValue dictionaryWithCapacity:self.parameterizationKeys.count];
  for (LTKeyBasicParameterizedObjectPair *pair in self.mapping) {
    result[pair.key] = @([pair.basicParameterizedObject floatForParametricValue:value]);
  }
  return [result copy];
}

- (LTParameterizationKeyToValues *)
    mappingForParametricValues:(const std::vector<CGFloat> &)parametricValues {
  LTParameterAssert(parametricValues.size() <= INT_MAX,
                    @"Number (%lu) of parametric values must not exceed INT_MAX",
                    (unsigned long)parametricValues.size());
  __block cv::Mat1g valuesPerKey((int)self.parameterizationKeys.count,
                                 (int)parametricValues.size());

  [self.parameterizationKeys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger i, BOOL *) {
    id<LTBasicParameterizedObject> object = [self baseParameterizedObjectForKey:key];
    for (int j = 0; j < (int)parametricValues.size(); ++j) {
      valuesPerKey((int)i, j) = (float)[object floatForParametricValue:parametricValues[j]];
    }
  }];

  return [[LTParameterizationKeyToValues alloc] initWithKeys:self.parameterizationKeys
                                                valuesPerKey:valuesPerKey];
}

- (CGFloat)floatForParametricValue:(CGFloat)value key:(NSString *)key {
  id<LTBasicParameterizedObject> object = [self baseParameterizedObjectForKey:key];
  return [object floatForParametricValue:value];
}

- (std::vector<CGFloat>)floatsForParametricValues:(const std::vector<CGFloat> &)values
                                              key:(NSString *)key {
  id<LTBasicParameterizedObject> object = [self baseParameterizedObjectForKey:key];
  std::vector<CGFloat> result(values.size());
  std::transform(values.begin(), values.end(), result.begin(), [object](const CGFloat &value) {
    return [object floatForParametricValue:value];
  });
  return result;
}

#pragma mark -
#pragma mark Auxiliary methods
#pragma mark -

- (id<LTBasicParameterizedObject>)baseParameterizedObjectForKey:(NSString *)key {
  id<LTBasicParameterizedObject> result =
      [self.mapping lt_find:^BOOL(LTKeyBasicParameterizedObjectPair *pair) {
    return [pair.key isEqualToString:key];
  }].basicParameterizedObject;
  LTParameterAssert(result,
                    @"No basic parameterized object specified for given key: \"%@\"", key);
  return result;
}

@end

NS_ASSUME_NONNULL_END
