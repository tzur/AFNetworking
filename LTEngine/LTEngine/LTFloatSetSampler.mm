// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTFloatSetSampler.h"

#import "LTFloatSet.h"
#import "LTParameterizationKeyToValues.h"
#import "LTParameterizedObject.h"
#import "LTSampleValues.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTFloatSetSampler ()

/// Initializes with the given \c initialModel.
- (instancetype)initWithInitialModel:(LTFloatSetSamplerModel *)initialModel
    NS_DESIGNATED_INITIALIZER;

/// Initial model of this object.
@property (strong, nonatomic) LTFloatSetSamplerModel *initialModel;

/// Remaining interval of values that can be provided as parametric values.
@property (nonatomic) lt::Interval<CGFloat> interval;

@end

@interface LTFloatSetSamplerModel ()

/// Interval determining the subset of real values that should be provided as parametric values, in
/// conjunction with the \c floatSet of this object.
@property (nonatomic) lt::Interval<CGFloat> interval;

@end

@implementation LTFloatSetSamplerModel : NSObject

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithFloatSet:(id<LTFloatSet>)floatSet
                        interval:(const lt::Interval<CGFloat> &)interval {
  LTParameterAssert(floatSet);

  if (self = [super init]) {
    _floatSet = floatSet;
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

- (BOOL)isEqual:(LTFloatSetSamplerModel *)model {
  if (self == model) {
    return YES;
  }

  if (![model isKindOfClass:[LTFloatSetSamplerModel class]]) {
    return NO;
  }

  return [self.floatSet isEqual:model.floatSet] && self.interval == model.interval;
}

- (NSUInteger)hash {
  return self.floatSet.hash ^ self.interval.hash();
}

#pragma mark -
#pragma mark LTContinuousSamplerModel
#pragma mark -

- (LTFloatSetSampler *)sampler {
  return [[LTFloatSetSampler alloc] initWithInitialModel:self];
}

@end

@implementation LTFloatSetSampler

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithInitialModel:(LTFloatSetSamplerModel *)initialModel {
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

static const lt::Interval<CGFloat>::EndpointInclusion kOpen =
    lt::Interval<CGFloat>::EndpointInclusion::Open;

static const lt::Interval<CGFloat>::EndpointInclusion kClosed =
    lt::Interval<CGFloat>::EndpointInclusion::Closed;

- (id<LTSampleValues>)nextSamplesFromParameterizedObject:(id<LTParameterizedObject>)object
                                   constrainedToInterval:(const lt::Interval<CGFloat> &)interval {
  lt::Interval<CGFloat> parametricRange({object.minParametricValue, object.maxParametricValue},
                                        kClosed);
  lt::Interval<CGFloat> intersection = self.interval.intersectionWith(parametricRange);
  intersection = intersection.intersectionWith(interval);

  if (intersection.isEmpty()) {
    return [[LTSampleValues alloc] initWithSampledParametricValues:{} mapping:nil];
  }

  std::vector<CGFloat> parametricValues = [self.floatSet discreteValuesInInterval:intersection];

  self.interval =
      lt::Interval<CGFloat>({intersection.sup(), self.interval.sup()},
                            intersection.supIncluded() ? kOpen : kClosed,
                            self.interval.supIncluded() ? kClosed : kOpen);

  LTParameterizationKeyToValues *mapping = [object mappingForParametricValues:parametricValues];
  mapping = mapping.numberOfValuesPerKey ? mapping : nil;

  return [[LTSampleValues alloc] initWithSampledParametricValues:parametricValues mapping:mapping];
}

- (id<LTFloatSet>)floatSet {
  return self.initialModel.floatSet;
}

- (lt::Interval<CGFloat>)initialInterval {
  return self.initialModel.interval;
}

- (LTFloatSetSamplerModel *)currentModel {
  return [[LTFloatSetSamplerModel alloc] initWithFloatSet:self.floatSet interval:self.interval];
}

@end

NS_ASSUME_NONNULL_END
