// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTParameterizedObjectStack.h"

#import "LTParameterizationKeyToValues.h"
#import "LTReparameterization.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTParameterizedObjectStack () {
  /// Mapping used to compute the reparameterization.
  std::vector<CGFloat> _mapping;
}

/// Reparameterization used to delegate queries to the corresponding parameterized object.
@property (strong, nonatomic) LTReparameterization *reparameterization;

/// Mutable ordered collection of parameterized objects constituting this instance.
@property (strong, nonatomic) NSMutableArray<id<LTParameterizedValueObject>> *mutableObjects;

/// Immutable ordered collection of parameterized objects returned to user. Reset after updates to
/// the state of the stack. Used for performance reasons.
@property (strong, nonatomic, nullable) NSArray<id<LTParameterizedValueObject>> *immutableObjects;

@end

@implementation LTParameterizedObjectStack

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithParameterizedObject:(id<LTParameterizedValueObject>)parameterizedObject {
  if (self = [super init]) {
    self.mutableObjects = [NSMutableArray arrayWithObject:parameterizedObject];
    [self resetImmutableObjects];
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
  [self resetImmutableObjects];
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
                     isEqualToOrderedSet:newObject.parameterizationKeys],
                    @"Parameterization keys of object to replace (%@) don't match those of new "
                    "object (%@)",
                    objectToReplace.parameterizationKeys.description,
                    newObject.parameterizationKeys.description);
  [self.mutableObjects replaceObjectAtIndex:index withObject:newObject];
  [self resetImmutableObjects];
}

- (nullable id<LTParameterizedValueObject>)popParameterizedObject {
  if (self.mutableObjects.count == 1) {
    return nil;
  }

  id<LTParameterizedValueObject> result = self.mutableObjects.lastObject;
  [self.mutableObjects removeLastObject];
  _mapping.pop_back();
  self.reparameterization = [[LTReparameterization alloc] initWithMapping:_mapping];
  [self resetImmutableObjects];
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
                     isEqualToOrderedSet:[self.mutableObjects.lastObject parameterizationKeys]],
                    @"Parameterization keys (%@) of pushed object must equal those (%@) of the "
                    "objects already held by this object",
                    [parameterizedObject parameterizationKeys],
                    [self.mutableObjects.lastObject parameterizationKeys]);
}

- (void)resetImmutableObjects {
  self.immutableObjects = nil;
}

#pragma mark -
#pragma mark LTParameterizedObject - Methods
#pragma mark -

- (LTParameterizationKeyToValue *)mappingForParametricValue:(CGFloat)value {
  NSUInteger index = [self indexOfObjectForParametricValue:value];
  return [self.mutableObjects[index] mappingForParametricValue:value];
}

- (LTParameterizationKeyToValues *)
    mappingForParametricValues:(const std::vector<CGFloat> &)parametricValues {
  LTParameterAssert(parametricValues.size() <= INT_MAX,
                    @"Number (%lu) of parametric values must not exceed INT_MAX",
                    (unsigned long)parametricValues.size());

  std::vector<NSUInteger> indices = [self indicesOfObjectsForParametricValues:parametricValues];

  int numberOfParametricValues = (int)parametricValues.size();
  __block cv::Mat1g valuesPerKey((int)self.parameterizationKeys.count, numberOfParametricValues);

  for (int i = 0; i < numberOfParametricValues; ++i) {
    std::vector<CGFloat> values = {parametricValues[i]};
    while (i + 1 < numberOfParametricValues && indices[i + 1] == indices[i]) {
      ++i;
      values.push_back(parametricValues[i]);
    }
    LTParameterizationKeyToValues *mapping =
        [self.mutableObjects[indices[i]] mappingForParametricValues:values];
    cv::Mat1g partialValuesPerKey = mapping.valuesPerKey;
    cv::Rect sourceRect(cv::Point(0, 0), cv::Size(partialValuesPerKey.cols,
                                                  partialValuesPerKey.rows));
    cv::Rect destinationRect(cv::Point(i + 1 - partialValuesPerKey.cols, 0), sourceRect.size());
    partialValuesPerKey(sourceRect).copyTo(valuesPerKey(destinationRect));
  }

  return [[LTParameterizationKeyToValues alloc] initWithKeys:self.parameterizationKeys
                                                valuesPerKey:valuesPerKey];
}

- (CGFloat)floatForParametricValue:(CGFloat)value key:(NSString *)key {
  NSUInteger index = [self indexOfObjectForParametricValue:value];
  return [self.mutableObjects[index] floatForParametricValue:value key:key];
}

- (std::vector<CGFloat>)floatsForParametricValues:(const std::vector<CGFloat> &)values
                                              key:(NSString *)key {
  std::vector<NSUInteger> indices = [self indicesOfObjectsForParametricValues:values];
  std::vector<CGFloat> floats(values.size());
  for (std::vector<CGFloat>::size_type i = 0; i < values.size(); ++i) {
    floats[i] = [self.mutableObjects[indices[i]] floatForParametricValue:values[i] key:key];
  }
  return floats;
}

#pragma mark -
#pragma mark LTParameterizedObject - Properties
#pragma mark -

- (NSOrderedSet<NSString *> *)parameterizationKeys {
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
  return std::clamp(std::floor(value * numberOfSplineSegments), 0., numberOfSplineSegments - 1.);
}

- (std::vector<NSUInteger>)
    indicesOfObjectsForParametricValues:(const std::vector<CGFloat> &)parametricValues {
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

- (NSUInteger)count {
  return self.mutableObjects.count;
}

- (NSArray<id<LTParameterizedValueObject>> *)parameterizedObjects {
  if (!self.immutableObjects) {
    self.immutableObjects = [self.mutableObjects copy];
  }
  return self.immutableObjects;
}

- (id<LTParameterizedValueObject>)bottom {
  return self.mutableObjects.firstObject;
}

- (id<LTParameterizedValueObject>)top {
  return self.mutableObjects.lastObject;
}

@end

NS_ASSUME_NONNULL_END
