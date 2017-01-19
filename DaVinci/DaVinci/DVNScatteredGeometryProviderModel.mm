// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNScatteredGeometryProviderModel.h"

#import <LTKit/LTRandom.h>

#import "DVNGeometryProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Geometry provider constructible from \c DVNScatteredGeometryProviderModel objects.
@interface DVNScatteredGeometryProvider : NSObject <DVNGeometryProvider>

/// Initializes with the given \c geometryProvider, \c randomState, \c count, \c distance, \c angle
/// and \c scale.
- (instancetype)initWithGeometryProvider:(id<DVNGeometryProvider>)geometryProvider
                             randomState:(LTRandomState *)randomState
                                   count:(lt::Interval<NSUInteger>)count
                                distance:(lt::Interval<CGFloat>)distance
                                   angle:(lt::Interval<CGFloat>)angle
                                   scale:(lt::Interval<CGFloat>)scale;

@end

@interface DVNScatteredGeometryProvider ()

/// Underlying geometry provider of this instance.
@property (readonly, nonatomic) id<DVNGeometryProvider> geometryProvider;

/// Support of the discrete uniform distribution used to draw values specify number of instances to
/// create for each quad.
@property (readonly, nonatomic) lt::Interval<NSUInteger> count;

/// Support of the uniform distribution used to draw values specify the translation. Must be in
/// range <tt>[0, inf)</tt>.
@property (readonly, nonatomic) lt::Interval<CGFloat> distance;

/// Support of the uniform distribution used to draw values specify the rotation.
@property (readonly, nonatomic) lt::Interval<CGFloat> angle;

/// Support of the uniform distribution used to draw values specify the scaling.
@property (readonly, nonatomic) lt::Interval<CGFloat> scale;

/// Random object for sampling flow.
@property (readonly, nonatomic) LTRandom *random;

@end

@implementation DVNScatteredGeometryProvider

- (instancetype)initWithGeometryProvider:(id<DVNGeometryProvider>)geometryProvider
                             randomState:(LTRandomState *)randomState
                                   count:(lt::Interval<NSUInteger>)count
                                distance:(lt::Interval<CGFloat>)distance
                                   angle:(lt::Interval<CGFloat>)angle
                                   scale:(lt::Interval<CGFloat>)scale {
  if (self = [super init]) {
    _random = [[LTRandom alloc] initWithState:randomState];
    _geometryProvider = geometryProvider;
    _count = count;
    _distance = distance;
    _angle = angle;
    _scale = scale;
  }
  return self;
}

- (dvn::GeometryValues)valuesFromSamples:(id<LTSampleValues>)samples end:(BOOL)end {
  dvn::GeometryValues values = [self.geometryProvider valuesFromSamples:samples end:end];
  const std::vector<lt::Quad> &originalQuads = values.quads();
  std::vector<lt::Quad> quads;
  quads.reserve(originalQuads.size());
  std::vector<NSUInteger> indices;
  indices.reserve(originalQuads.size());
  
  for (NSUInteger index : values.indices()) {
    NSUInteger count = [self.random randomIntegerBetweenMin:(int)self.count.min()
                                                        max:(int)self.count.max()];
    
    for (NSUInteger i = 0; i < count; ++i) {
      quads.push_back([self randomlyTransformedQuadFromQuad:originalQuads[index]]);
      indices.push_back(index);
    }
  }
  return dvn::GeometryValues(quads, indices, values.samples());
}

- (lt::Quad)randomlyTransformedQuadFromQuad:(lt::Quad)quad {
  CGFloat distanceLength = [self.random randomDoubleBetweenMin:self.distance.min()
                                                           max:self.distance.max()];
  CGPoint distance = CGPoint(LTVector2::angle([self.random randomDoubleBetweenMin:0 max:M_PI * 2]) *
                             distanceLength);
  CGFloat angle = [self.random randomDoubleBetweenMin:self.angle.min() max:self.angle.max()];
  CGFloat scale = [self.random randomDoubleBetweenMin:self.scale.min() max:self.scale.max()];
  return quad
      .rotatedAroundPoint(angle, quad.center())
      .scaledAround(scale, quad.center())
      .translatedBy(distance);
}

- (id<DVNGeometryProviderModel>)currentModel {
  id<DVNGeometryProviderModel> model = [self.geometryProvider currentModel];
  LTRandomState *randomState = self.random.engineState;
  return [[DVNScatteredGeometryProviderModel alloc] initWithGeometryProviderModel:model
                                                                      randomState:randomState
                                                                            count:self.count
                                                                         distance:self.distance
                                                                            angle:self.angle
                                                                            scale:self.scale];
}

@end

@implementation DVNScatteredGeometryProviderModel

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithGeometryProviderModel:(id<DVNGeometryProviderModel>)geometryProviderModel
                                  randomState:(LTRandomState *)randomState
                                        count:(lt::Interval<NSUInteger>)count
                                     distance:(lt::Interval<CGFloat>)distance
                                        angle:(lt::Interval<CGFloat>)angle
                                        scale:(lt::Interval<CGFloat>)scale {
  [self validateDistance:distance angle:angle scale:scale];
  
  if (self = [super init]) {
    _geometryProviderModel = geometryProviderModel;
    _randomState = randomState;
    _count = count;
    _distance = distance;
    _angle = angle;
    _scale = scale;
  }
  return self;
}

- (void)validateDistance:(lt::Interval<CGFloat>)distance angle:(lt::Interval<CGFloat>)angle
                   scale:(lt::Interval<CGFloat>)scale {
  lt::Interval<CGFloat> validInterval({0, CGFLOAT_MAX},
                                      lt::Interval<CGFloat>::EndpointInclusion::Closed);
  LTParameterAssert(distance.intersects(validInterval),
                    @"Interval ([%g, %g]) outside valid distance interval ([0, CGFLOAT_MAX))",
                    distance.min(), distance.max());
  validInterval = lt::Interval<CGFloat>({0, 2 * M_PI},
                                        lt::Interval<CGFloat>::EndpointInclusion::Closed,
                                        lt::Interval<CGFloat>::EndpointInclusion::Closed);
  LTParameterAssert(angle.intersects(validInterval),
                    @"Interval ([%g, %g]) outside valid angle interval ([0, 2 * PI])",
                    angle.min(), angle.max());
  validInterval = lt::Interval<CGFloat>({0, CGFLOAT_MAX},
                                        lt::Interval<CGFloat>::EndpointInclusion::Open,
                                        lt::Interval<CGFloat>::EndpointInclusion::Closed);
  LTParameterAssert(scale.intersects(validInterval),
                    @"Interval ([%g, %g]) outside valid scaling interval ((0, CGFLOAT_MAX))",
                    scale.min(), scale.max());
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(DVNScatteredGeometryProviderModel *)model {
  if (self == model) {
    return YES;
  }
  
  if (![model isKindOfClass:[DVNScatteredGeometryProviderModel class]]) {
    return NO;
  }
  
  return [self.geometryProviderModel isEqual:model.geometryProviderModel] &&
      [self.randomState isEqual:model.randomState] && self.count == model.count &&
      self.distance == model.distance && self.angle == model.angle && self.scale == model.scale;
}

- (NSUInteger)hash {
  size_t seed = 0;
  lt::hash_combine(seed, [self.geometryProviderModel hash]);
  lt::hash_combine(seed, [self.randomState hash]);
  lt::hash_combine(seed, self.count.hash());
  lt::hash_combine(seed, self.distance.hash());
  lt::hash_combine(seed, self.angle.hash());
  lt::hash_combine(seed, self.scale.hash());
  return seed;
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (instancetype)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

#pragma mark -
#pragma mark DVNGeometryProviderModel
#pragma mark -

- (id<DVNGeometryProvider>)provider {
  id<DVNGeometryProvider> provider = [self.geometryProviderModel provider];
  return [[DVNScatteredGeometryProvider alloc] initWithGeometryProvider:provider
                                                            randomState:self.randomState
                                                                  count:self.count
                                                               distance:self.distance
                                                                  angle:self.angle
                                                                  scale:self.scale];
}

@end

NS_ASSUME_NONNULL_END
