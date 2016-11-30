// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNPatternSamplingStageModel.h"

#import <LTEngine/LTFloatSetSampler.h>
#import <LTEngine/LTPeriodicFloatSet.h>
#import <LTKit/NSArray+NSSet.h>

NS_ASSUME_NONNULL_BEGIN

@implementation DVNPatternSamplingStageModel

#pragma mark -
#pragma mark MTLModel
#pragma mark -

+ (NSSet<NSString *> *)serializableKeyPaths {
  return [self propertyKeys];
}

#pragma mark -
#pragma mark LTJSONSerializing
#pragma mark -

+ (NSSet<NSString *> *)propertyKeys {
  NSMutableSet *keys = [[super propertyKeys] mutableCopy];
  [keys minusSet:[@[
    @instanceKeypath(DVNPatternSamplingStageModel, __sequenceDistanceSet),
    @instanceKeypath(DVNPatternSamplingStageModel, __numberOfSamplesPerSequenceSet),
    @instanceKeypath(DVNPatternSamplingStageModel, __spacingSet)
  ] lt_set]];
  return [keys copy];
}

#pragma mark -
#pragma mark MTLJSONSerializing
#pragma mark -

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{};
}

#pragma mark -
#pragma mark DVNSamplingStageModel
#pragma mark -

- (id<LTContinuousSamplerModel>)continuousSamplerModel {
  LTPeriodicFloatSet *floatSet =
      [[LTPeriodicFloatSet alloc] initWithPivotValue:0
                           numberOfValuesPerSequence:self.numberOfSamplesPerSequence
                                       valueDistance:self.spacing
                                    sequenceDistance:self.sequenceDistance];
  lt::Interval<CGFloat> interval({0, CGFLOAT_MAX},
                                 lt::Interval<CGFloat>::EndpointInclusion::Closed);
  return [[LTFloatSetSamplerModel alloc] initWithFloatSet:floatSet interval:interval];
}

@end

NS_ASSUME_NONNULL_END
