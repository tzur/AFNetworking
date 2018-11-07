// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTCompoundParameterizedObjectFactory.h"

#import <LTKit/NSArray+Functional.h>

#import "LTBasicParameterizedObjectFactory.h"
#import "LTCompoundParameterizedObject.h"
#import "LTInterpolatableObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTCompoundParameterizedObjectFactory ()

/// Factory used to create the basic parameterized objects constituting the parameterized
/// objects which can be created by this instance.
@property (strong, readwrite, nonatomic) id<LTBasicParameterizedObjectFactory> factory;

@end

@implementation LTCompoundParameterizedObjectFactory

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithBasicFactory:(id<LTBasicParameterizedObjectFactory>)factory {
  if (self = [super init]) {
    self.factory = factory;
  }
  return self;
}

#pragma mark -
#pragma mark Public interface
#pragma mark -

- (LTCompoundParameterizedObject *)parameterizedObjectFromInterpolatableObjects:
    (NSArray<id<LTInterpolatableObject>> *)objects {
  LTParameterAssert(objects.count == [[self.factory class] numberOfRequiredValues],
                    @"Number of provided interpolatable objects (%lu) does not match number of "
                    "required values (%lu)", (unsigned long)objects.count,
                    (unsigned long)[[self.factory class] numberOfRequiredValues]);
  NSArray<NSString *> *propertiesToInterpolate =
      [objects.firstObject propertiesToInterpolate].allObjects;

  // TODO(rouven): If required, parallelize the iterations of this loop.
  LTKeyToBaseParameterizedObject *mapping =
      [propertiesToInterpolate lt_map:^LTKeyBasicParameterizedObjectPair *(NSString *propertyName) {
    std::vector<CGFloat> values;
    for (NSObject<LTInterpolatableObject> *object in objects) {
      values.push_back([[object valueForKey:propertyName] CGFloatValue]);
    }
    return [LTKeyBasicParameterizedObjectPair
            pairWithKey:propertyName
            basicParameterizedObject:[self.factory baseParameterizedObjectsFromValues:values]];
  }];
  return [[LTCompoundParameterizedObject alloc] initWithMapping:mapping];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (NSUInteger)numberOfRequiredInterpolatableObjects {
  return [[self.factory class] numberOfRequiredValues];
}

- (NSRange)intrinsicParametricRange {
  return [[self.factory class] intrinsicParametricRange];
}

@end

NS_ASSUME_NONNULL_END
