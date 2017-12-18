// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNPatternSamplingStageModel.h"

#import <LTEngine/LTFloatSetSampler.h>
#import <LTEngine/LTPeriodicFloatSet.h>
#import <LTKit/NSArray+Functional.h>
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
  return [[[[super propertyKeys] allObjects]
      lt_filter:^BOOL(NSString *key) {
        return ![key hasPrefix:@"__"];
      }]
      lt_set];
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

#pragma mark -
#pragma mark Properties
#pragma mark -

DVNProperty(CGFloat, spacing, Spacing, 0.01, CGFLOAT_MAX, 1);
DVNProperty(CGFloat, sequenceDistance, SequenceDistance, 0.01, CGFLOAT_MAX, 1);
DVNProperty(NSUInteger, numberOfSamplesPerSequence, NumberOfSamplesPerSequence, 1, NSUIntegerMax,
            1);

@end

NS_ASSUME_NONNULL_END
