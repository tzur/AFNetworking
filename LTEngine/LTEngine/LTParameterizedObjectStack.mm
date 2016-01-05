// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTParameterizedObjectStack.h"

#import "LTReparameterization.h"

NS_ASSUME_NONNULL_BEGIN

/// Represents mutable mapping from key to ordered collection of boxed \c CGFloat returned by
/// parameterized objects.
typedef NSMutableDictionary<NSString *, NSArray<NSNumber *> *> LTMutableParameterizationKeyToValues;

@interface LTParameterizedObjectStack () {
  /// Mapping used to compute the reparameterization.
  CGFloats _mapping;
}

/// Reparameterization used to delegate queries to the corresponding parameterized object.
@property (strong, nonatomic) LTReparameterization *reparameterization;

/// Mutable ordered collection of parameterized objects constituting this instance.
@property (strong, nonatomic) NSMutableArray<id<LTParameterizedValueObject>> *mutableObjects;

/// Immutable ordered collection of parameterized objects returned to user. Updated after updates to
/// the state of the stack. Used for performance reasons.
@property (strong, readwrite, nonatomic) NSArray<id<LTParameterizedValueObject>> *immutableObjects;

@end

@implementation LTParameterizedObjectStack

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithParameterizedObject:(id<LTParameterizedValueObject>)parameterizedObject {
  if (self = [super init]) {
    self.mutableObjects = [NSMutableArray arrayWithObject:parameterizedObject];
    [self updateImmutableObjects];
    _mapping.assign({parameterizedObject.minParametricValue,
                     parameterizedObject.maxParametricValue});
  }
  return self;
}

#pragma mark -
#pragma mark Public interface
#pragma mark -

- (void)pushParameterizedObject:(id<LTParameterizedValueObject>)parameterizedObject {
  [self validatePushedParameterizedObject:parameterizedObject];
  [self.mutableObjects addObject:parameterizedObject];
  _mapping.push_back(parameterizedObject.maxParametricValue);
  self.reparameterization = [[LTReparameterization alloc] initWithMapping:_mapping];
  [self updateImmutableObjects];
}

- (void)replaceParameterizedObject:(id<LTParameterizedValueObject>)objectToReplace
                          byObject:(id<LTParameterizedValueObject>)newObject {
  NSUInteger index = [self.mutableObjects indexOfObject:objectToReplace];
  LTParameterAssert(index != NSNotFound, @"Object (%@) to replace not found", objectToReplace);
  LTParameterAssert(objectToReplace.minParametricValue == newObject.minParametricValue &&
                    objectToReplace.maxParametricValue == newObject.maxParametricValue,
                    @"Intrinsic parametric range [%g, %g] of new object doesn't match the range "
                    "[%g, %g] of the object to replace", newObject.minParametricValue,
                    newObject.maxParametricValue, objectToReplace.minParametricValue,
                    objectToReplace.maxParametricValue);
  LTParameterAssert([objectToReplace.parameterizationKeys
                     isSubsetOfSet:newObject.parameterizationKeys],
                    @"Parameterization keys of object to replace (%@) don't match those of new "
                    "object (%@)",
                    objectToReplace.parameterizationKeys.description,
                    newObject.parameterizationKeys.description);
  [self.mutableObjects replaceObjectAtIndex:index withObject:newObject];
  [self updateImmutableObjects];
}

- (nullable id<LTParameterizedValueObject>)popParameterizedObject {
  if (self.mutableObjects.count == 1) {
    return nil;
  }

  id<LTParameterizedValueObject> result = self.mutableObjects.lastObject;
  [self.mutableObjects removeLastObject];
  _mapping.pop_back();
  self.reparameterization = [[LTReparameterization alloc] initWithMapping:_mapping];
  [self updateImmutableObjects];
  return result;
}

#pragma mark -
#pragma mark Public interface - Auxiliary methods
#pragma mark -

- (void)validatePushedParameterizedObject:(id<LTParameterizedValueObject>)parameterizedObject {
  LTParameterAssert(parameterizedObject.minParametricValue < parameterizedObject.maxParametricValue,
                    @"Minimum value (%g) of intrinsic parametric range must be smaller than "
                    "maximum value (%g)", parameterizedObject.minParametricValue,
                    parameterizedObject.maxParametricValue);
  LTParameterAssert(parameterizedObject.minParametricValue ==
                    self.mutableObjects.lastObject.maxParametricValue,
                    @"Minimum value (%g) of intrinsic parametric range of pushed object must equal "
                    "maximum value (%g) of last object", parameterizedObject.minParametricValue,
                    self.mutableObjects.lastObject.maxParametricValue);
  LTParameterAssert([[parameterizedObject parameterizationKeys]
                     isEqualToSet:[self.mutableObjects.lastObject parameterizationKeys]],
                    @"Parameterization keys (%@) of pushed object must equal those (%@) of the "
                    "objects already held by this object",
                    [parameterizedObject parameterizationKeys],
                    [self.mutableObjects.lastObject parameterizationKeys]);
}

- (void)updateImmutableObjects {
  self.immutableObjects = [self.mutableObjects copy];
}

#pragma mark -
#pragma mark LTParameterizedObject - Methods
#pragma mark -

- (LTParameterizationKeyToValue *)mappingForParametricValue:(CGFloat)value {
  NSUInteger index = [self indexOfObjectForParametricValue:value];
  return [self.mutableObjects[index] mappingForParametricValue:value];
}

- (LTParameterizationKeyToValues *)mappingForParametricValues:(const CGFloats &)values {
  std::vector<NSUInteger> indices = [self indicesOfObjectsForParametricValues:values];

  LTMutableParameterizationKeyToValues *resultMapping =
      [NSMutableDictionary dictionaryWithCapacity:self.parameterizationKeys.count];

  for (NSString *key in self.parameterizationKeys) {
    NSMutableArray<NSNumber *> *mutableArray = [NSMutableArray arrayWithCapacity:values.size()];

    for (CGFloats::size_type i = 0; i < values.size(); ++i) {
      CGFloat value = [self.mutableObjects[indices[i]] floatForParametricValue:values[i] key:key];
      [mutableArray addObject:@(value)];
    }

    resultMapping[key] = [mutableArray copy];
  }

  return [resultMapping copy];
}

- (CGFloat)floatForParametricValue:(CGFloat)value key:(NSString *)key {
  NSUInteger index = [self indexOfObjectForParametricValue:value];
  return [self.mutableObjects[index] floatForParametricValue:value key:key];
}

- (CGFloats)floatsForParametricValues:(const CGFloats &)values key:(NSString *)key {
  std::vector<NSUInteger> indices = [self indicesOfObjectsForParametricValues:values];
  CGFloats floats(values.size());
  for (CGFloats::size_type i = 0; i < values.size(); ++i) {
    floats[i] = [self.mutableObjects[indices[i]] floatForParametricValue:values[i] key:key];
  }
  return floats;
}

#pragma mark -
#pragma mark LTParameterizedObject - Properties
#pragma mark -

- (NSSet<NSString *> *)parameterizationKeys {
  return [self.mutableObjects.firstObject parameterizationKeys];
}

- (CGFloat)minParametricValue {
  return self.mutableObjects.firstObject.minParametricValue;
}

- (CGFloat)maxParametricValue {
  return self.mutableObjects.lastObject.maxParametricValue;
}

#pragma mark -
#pragma mark LTParameterizedObject - Auxiliary methods
#pragma mark -

- (NSUInteger)indexOfObjectForParametricValue:(CGFloat)parametricValue {
  CGFloat value = [self.reparameterization floatForParametricValue:parametricValue];
  NSUInteger numberOfSplineSegments = self.mutableObjects.count;
  return std::clamp(std::floor(value * numberOfSplineSegments), 0, numberOfSplineSegments - 1);
}

- (std::vector<NSUInteger>)indicesOfObjectsForParametricValues:(const CGFloats &)parametricValues {
  std::vector<NSUInteger> indices(parametricValues.size());
  std::transform(parametricValues.cbegin(), parametricValues.cend(), indices.begin(),
                 [self](const CGFloat parametricValue) {
    return [self indexOfObjectForParametricValue:parametricValue];
  });
  return indices;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (NSArray<id<LTParameterizedValueObject>> *)parameterizedObjects {
  return self.immutableObjects;
}

@end

NS_ASSUME_NONNULL_END
