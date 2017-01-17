// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNScatteredGeometryStageModel.h"

#import <LTKit/LTRandom.h>
#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSArray+NSSet.h>

#import "DVNScatteredGeometryProviderModel.h"
#import "DVNSquareProvider.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DVNScatteredGeometryStageModel

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
#pragma mark DVNGeometryStageModel
#pragma mark -

- (id<DVNGeometryProviderModel>)geometryProviderModel {
  DVNSquareProviderModel *providerModel =
      [[DVNSquareProviderModel alloc] initWithEdgeLength:self.diameter];
  lt::Interval<CGFloat> distance({self.minDistance, self.maxDistance},
                                 lt::Interval<CGFloat>::EndpointInclusion::Closed);
  lt::Interval<CGFloat> angle({self.minAngle, self.maxAngle},
                              lt::Interval<CGFloat>::EndpointInclusion::Closed);
  lt::Interval<CGFloat> scale({self.minScale, self.maxScale},
                              lt::Interval<CGFloat>::EndpointInclusion::Closed);
  lt::Interval<NSUInteger> count({self.minCount, self.maxCount},
                                 lt::Interval<NSUInteger>::EndpointInclusion::Closed);
  return [[DVNScatteredGeometryProviderModel alloc]
          initWithGeometryProviderModel:providerModel randomState:[[LTRandomState alloc] init]
          count:count distance:distance angle:angle scale:scale];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

DVNProperty(CGFloat, diameter, Diameter, 0.01, CGFLOAT_MAX, 1);
DVNProperty(NSUInteger, minCount, MinCount, 0, NSUIntegerMax, 1);
DVNProperty(NSUInteger, maxCount, MaxCount, 0, NSUIntegerMax, 1);
DVNProperty(CGFloat, minDistance, MinDistance, 0, CGFLOAT_MAX, 0);
DVNProperty(CGFloat, maxDistance, MaxDistance, 0, CGFLOAT_MAX, 0);
DVNProperty(CGFloat, minAngle, MinAngle, 0, M_PI * 2, 0);
DVNProperty(CGFloat, maxAngle, MaxAngle, 0, M_PI * 2, 0);
DVNProperty(CGFloat, minScale, MinScale, 0, CGFLOAT_MAX, 1);
DVNProperty(CGFloat, maxScale, MaxScale, 0, CGFLOAT_MAX, 1);

@end

NS_ASSUME_NONNULL_END
