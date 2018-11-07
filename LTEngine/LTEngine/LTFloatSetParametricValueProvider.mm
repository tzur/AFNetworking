// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTFloatSetParametricValueProvider.h"

#import <LTEngine/LTFloatSet.h>
#import <LTEngine/LTParameterizedObject.h>

NS_ASSUME_NONNULL_BEGIN

/// Interval of \c CGFloat values.
typedef lt::Interval<CGFloat> CGFloatInterval;

@interface LTFloatSetParametricValueProvider ()

/// Initializes with the given \c initialModel.
- (instancetype)initWithInitialModel:(LTFloatSetParametricValueProviderModel *)initialModel;

/// Initial model of this object.
@property (strong, nonatomic) LTFloatSetParametricValueProviderModel *initialModel;

/// Remaining interval of values that can be provided as parametric values.
@property (nonatomic) CGFloatInterval interval;

@end

@interface LTFloatSetParametricValueProviderModel ()

/// Float set determining the subset of real values that should be provided as parametric values, in
/// conjunction with the \c interval of this object.
@property (strong, nonatomic) id<LTFloatSet> floatSet;

/// Interval determining the subset of real values that should be provided as parametric values, in
/// conjunction with the \c floatSet of this object.
@property (nonatomic) CGFloatInterval interval;

@end

@implementation LTFloatSetParametricValueProviderModel : NSObject

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithFloatSet:(id<LTFloatSet>)floatSet interval:(CGFloatInterval)interval {
  LTParameterAssert(floatSet);

  if (self = [super init]) {
    self.floatSet = floatSet;
    self.interval = interval;
  }
  return self;
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (instancetype)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(LTFloatSetParametricValueProviderModel *)model {
  if (self == model) {
    return YES;
  }

  if (![model isKindOfClass:[LTFloatSetParametricValueProviderModel class]]) {
    return NO;
  }

  return [self.floatSet isEqual:model.floatSet] && self.interval == model.interval;
}

- (NSUInteger)hash {
  return self.floatSet.hash ^ self.interval.hash();
}

#pragma mark -
#pragma mark LTContinuousParametricValueProviderModel
#pragma mark -

- (LTFloatSetParametricValueProvider *)provider {
  return [[LTFloatSetParametricValueProvider alloc] initWithInitialModel:self];
}

@end

@implementation LTFloatSetParametricValueProvider

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithInitialModel:(LTFloatSetParametricValueProviderModel *)initialModel {
  LTParameterAssert(initialModel);

  if (self = [super init]) {
    self.initialModel = initialModel;
    self.interval = initialModel.interval;
  }
  return self;
}

#pragma mark -
#pragma mark Public Interface
#pragma mark -

static const CGFloatInterval::EndpointInclusion kOpen = CGFloatInterval::EndpointInclusion::Open;

static const CGFloatInterval::EndpointInclusion kClosed =
    CGFloatInterval::EndpointInclusion::Closed;

- (std::vector<CGFloat>)
    nextParametricValuesForParameterizedObject:(id<LTParameterizedObject>)object {
  CGFloatInterval interval({object.minParametricValue, object.maxParametricValue},
                           kClosed, kClosed);
  CGFloatInterval intersection = self.interval.intersectionWith(interval);

  if (intersection.isEmpty()) {
    return {};
  }

  std::vector<CGFloat> parametricValues = [self.floatSet discreteValuesInInterval:intersection];

  self.interval = CGFloatInterval({intersection.sup(), self.interval.sup()},
                                  intersection.supIncluded() ? kOpen : kClosed,
                                  self.interval.supIncluded() ? kClosed : kOpen);

  return parametricValues;
}

- (id<LTFloatSet>)floatSet {
  return self.initialModel.floatSet;
}

- (CGFloatInterval)initialInterval {
  return self.initialModel.interval;
}

- (LTFloatSetParametricValueProviderModel *)currentModel {
  return [[LTFloatSetParametricValueProviderModel alloc] initWithFloatSet:self.floatSet
                                                                 interval:self.interval];
}

@end

NS_ASSUME_NONNULL_END
