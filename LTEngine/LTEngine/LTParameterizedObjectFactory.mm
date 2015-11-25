// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTParameterizedObjectFactory.h"

#import "LTCompoundParameterizedObject.h"
#import "LTInterpolatableObject.h"
#import "LTPrimitiveParameterizedObjectFactory.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTParameterizedObjectFactory ()

/// Factory used to create the primitive parameterized objects constituting the parameterized
/// objects which can be created by this instance.
@property (strong, readwrite, nonatomic) id<LTPrimitiveParameterizedObjectFactory> primitiveFactory;

@end

@implementation LTParameterizedObjectFactory

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithPrimitiveFactory:(id<LTPrimitiveParameterizedObjectFactory>)factory {
  if (self = [super init]) {
    self.primitiveFactory = factory;
  }
  return self;
}

#pragma mark -
#pragma mark Public interface
#pragma mark -

- (id<LTParameterizedObject>)parameterizedObjectFromInterpolatableObjects:
    (NSArray<id<LTInterpolatableObject>> *)objects {
  LTParameterAssert(objects.count == [[self.primitiveFactory class] numberOfRequiredValues],
                    @"Number of provided interpolatable objects (%lu) does not match number of "
                    "required values (%lu)", (unsigned long)objects.count,
                    (unsigned long)[[self.primitiveFactory class] numberOfRequiredValues]);
  NSSet<NSString *> *propertiesToInterpolate = [objects.firstObject propertiesToInterpolate];
  LTMutableKeyToPrimitiveParameterizedObject *mapping =
      [LTMutableKeyToPrimitiveParameterizedObject
       dictionaryWithCapacity:propertiesToInterpolate.count];

  // TODO(rouven): If required, parallelize the iterations of this loop.
  for (NSString *propertyName in propertiesToInterpolate) {
    CGFloats values;
    for (NSObject<LTInterpolatableObject> *object in objects) {
      values.push_back([[object valueForKey:propertyName] CGFloatValue]);
    }
    mapping[propertyName] = [self.primitiveFactory primitiveParameterizedObjectsFromValues:values];
  }
  return [[LTCompoundParameterizedObject alloc] initWithMapping:mapping];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (NSUInteger)numberOfRequiredInterpolatableObjects {
  return [[self.primitiveFactory class] numberOfRequiredValues];
}

- (NSRange)intrinsicParametricRange {
  return [[self.primitiveFactory class] intrinsicParametricRange];
}

@end

NS_ASSUME_NONNULL_END
