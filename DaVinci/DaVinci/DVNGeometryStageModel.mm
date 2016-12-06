// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNGeometryStageModel.h"

#import <LTKit/LTRandom.h>
#import <LTKit/NSArray+NSSet.h>

#import "DVNScatteredGeometryProviderModel.h"
#import "DVNSquareProvider.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DVNGeometryStageModel

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
  [keys removeObject:@instanceKeypath(DVNGeometryStageModel, __diameterSet)];
  return [keys copy];
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
  lt::Interval<CGFloat> distance({self.minScatterDistance, self.maxScatterDistance},
                                 lt::Interval<CGFloat>::EndpointInclusion::Closed);
  lt::Interval<CGFloat> angle({self.minScatterAngle, self.maxScatterAngle},
                              lt::Interval<CGFloat>::EndpointInclusion::Closed);
  lt::Interval<CGFloat> scale({self.minScatterScale, self.maxScatterScale},
                              lt::Interval<CGFloat>::EndpointInclusion::Closed);
  return [[DVNScatteredGeometryProviderModel alloc]
          initWithGeometryProviderModel:providerModel randomState:[[LTRandomState alloc] init]
          maximumCount:self.maxScatterCount distance:distance angle:angle scale:scale];
}

@end

NS_ASSUME_NONNULL_END
