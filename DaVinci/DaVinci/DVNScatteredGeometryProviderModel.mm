// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNScatteredGeometryProviderModel.h"

#import <LTKit/LTRandom.h>

#import "DVNGeometryProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVNScatteredGeometryProviderModel ()

/// Returns a new instance equal to this instance, with the exception of the given
/// \c geometryProviderModel and \c randomState.
- (instancetype)copyWithGeometryProviderModel:(id<DVNGeometryProviderModel>)geometryProviderModel
                                  randomState:(LTRandomState *)randomState;

@end

/// Geometry provider constructible from \c DVNScatteredGeometryProviderModel objects.
@interface DVNScatteredGeometryProvider : NSObject <DVNGeometryProvider>

/// Initializes with the given \c geometryProvider and \c model.
- (instancetype)initWithGeometryProvider:(id<DVNGeometryProvider>)geometryProvider
                                   model:(DVNScatteredGeometryProviderModel *)model;

@end

@interface DVNScatteredGeometryProvider ()

/// Underlying geometry provider of this instance.
@property (readonly, nonatomic) id<DVNGeometryProvider> geometryProvider;

/// Random object for sampling flow.
@property (readonly, nonatomic) LTRandom *random;

/// Model provided upon initialization.
@property (readonly, nonatomic) DVNScatteredGeometryProviderModel *model;

/// Indication whether tapering is performed.
@property (readonly, nonatomic) BOOL performsTapering;

@end

@implementation DVNScatteredGeometryProvider

- (instancetype)initWithGeometryProvider:(id<DVNGeometryProvider>)geometryProvider
                                   model:(DVNScatteredGeometryProviderModel *)model {
  if (self = [super init]) {
    _random = [[LTRandom alloc] initWithState:model.randomState];
    _geometryProvider = geometryProvider;
    _model = model;
    _performsTapering = (model.lengthOfStartTapering > 0 || model.lengthOfEndTapering > 0) &&
        model.minimumTaperingScaleFactor < 1;
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

  CGFloats sampledParametricValues = samples.sampledParametricValues;
  CGFloat minParametricValue = sampledParametricValues.front();
  CGFloat maxParametricValue = sampledParametricValues.back();
  CGFloat length = maxParametricValue - minParametricValue;

  for (NSUInteger i = 0; i < sampledParametricValues.size(); ++i) {
    NSUInteger count = [self.random randomIntegerBetweenMin:(int)self.model.count.inf()
                                                        max:(int)self.model.count.sup()];
    CGFloat taperingScaleFactor = 1;

    if (self.performsTapering) {
      CGFloat parametricValue = sampledParametricValues[i];
      taperingScaleFactor = std::min((parametricValue + 1) / self.model.lengthOfStartTapering,
                                     (CGFloat)1.0);
      if (end) {
        CGFloat endTaperingScaleFactor =
            std::min(length > self.model.lengthOfEndTapering ?
                     (maxParametricValue - parametricValue) / self.model.lengthOfEndTapering :
                     (maxParametricValue - parametricValue) / length, (CGFloat)1.0);
        taperingScaleFactor *= endTaperingScaleFactor;
      }
      taperingScaleFactor = std::max(pow(taperingScaleFactor, self.model.taperingExponent),
                                     self.model.minimumTaperingScaleFactor);
    }

    NSUInteger index = values.indices()[i];

    for (NSUInteger j = 0; j < count; ++j) {
      quads.push_back([self randomlyTransformedQuadFromQuad:originalQuads[index]
                                        taperingScaleFactor:taperingScaleFactor]);
      indices.push_back(index);
    }
  }
  return dvn::GeometryValues(quads, indices, values.samples());
}

- (lt::Quad)randomlyTransformedQuadFromQuad:(lt::Quad)quad
                        taperingScaleFactor:(CGFloat)taperingScaleFactor {
  CGFloat distanceLength = [self.random randomDoubleBetweenMin:self.model.distance.inf()
                                                           max:self.model.distance.sup()];
  CGPoint distance = CGPoint(LTVector2::angle([self.random randomDoubleBetweenMin:0 max:M_PI * 2]) *
                             distanceLength);
  CGFloat angle = [self.random randomDoubleBetweenMin:self.model.angle.inf()
                                                  max:self.model.angle.sup()];
  CGFloat scale = [self.random randomDoubleBetweenMin:self.model.scale.inf()
                                                  max:self.model.scale.sup()];
  return quad
      .rotatedAroundPoint(angle, quad.center())
      .scaledBy(scale * taperingScaleFactor)
      .translatedBy(distance * taperingScaleFactor);
}

- (id<DVNGeometryProviderModel>)currentModel {
  id<DVNGeometryProviderModel> model = [self.geometryProvider currentModel];
  LTRandomState *randomState = self.random.engineState;
  return [self.model copyWithGeometryProviderModel:model randomState:randomState];
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
  return [self initWithGeometryProviderModel:geometryProviderModel randomState:randomState
                                       count:count distance:distance angle:angle scale:scale
                       lengthOfStartTapering:0 lengthOfEndTapering:0 taperingExponent:1
                  minimumTaperingScaleFactor:1];
}

- (instancetype)initWithGeometryProviderModel:(id<DVNGeometryProviderModel>)geometryProviderModel
                                  randomState:(LTRandomState *)randomState
                                        count:(lt::Interval<NSUInteger>)count
                                     distance:(lt::Interval<CGFloat>)distance
                                        angle:(lt::Interval<CGFloat>)angle
                                        scale:(lt::Interval<CGFloat>)scale
                        lengthOfStartTapering:(CGFloat)lengthOfStartTapering
                          lengthOfEndTapering:(CGFloat)lengthOfEndTapering
                             taperingExponent:(CGFloat)taperingExponent
                   minimumTaperingScaleFactor:(CGFloat)minimumTaperingScaleFactor {
  [self validateDistance:distance angle:angle scale:scale
   lengthOfStartTapering:lengthOfStartTapering lengthOfEndTapering:lengthOfEndTapering
        taperingExponent:taperingExponent minimumTaperingScaleFactor:minimumTaperingScaleFactor];

  if (self = [super init]) {
    _geometryProviderModel = geometryProviderModel;
    _randomState = randomState;
    _count = count;
    _distance = distance;
    _angle = angle;
    _scale = scale;
    _lengthOfStartTapering = lengthOfStartTapering;
    _lengthOfEndTapering = lengthOfEndTapering;
    _taperingExponent = taperingExponent;
    _minimumTaperingScaleFactor = minimumTaperingScaleFactor;
  }
  return self;
}

- (void)validateDistance:(lt::Interval<CGFloat>)distance angle:(lt::Interval<CGFloat>)angle
                   scale:(lt::Interval<CGFloat>)scale
   lengthOfStartTapering:(CGFloat)lengthOfStartTapering
     lengthOfEndTapering:(CGFloat)lengthOfEndTapering taperingExponent:(CGFloat)taperingExponent
      minimumTaperingScaleFactor:(CGFloat)minimumTaperingScaleFactor {
  lt::Interval<CGFloat> nonNegativeNumbers({0, CGFLOAT_MAX});
  LTParameterAssert(distance.intersects(nonNegativeNumbers),
                    @"Interval %@ outside valid distance interval ([0, CGFLOAT_MAX])",
                    distance.description());
  lt::Interval<CGFloat> validAngleInterval({0, 2 * M_PI});
  LTParameterAssert(angle.intersects(validAngleInterval),
                    @"Interval %@ outside valid angle interval ([0, 2 * PI])",
                    angle.description());
  lt::Interval<CGFloat> positiveNumbers({0, CGFLOAT_MAX},
                                        lt::Interval<CGFloat>::EndpointInclusion::Open,
                                        lt::Interval<CGFloat>::EndpointInclusion::Closed);
  LTParameterAssert(scale.intersects(positiveNumbers),
                    @"Interval %@ outside valid scaling interval ((0, CGFLOAT_MAX])",
                    scale.description());
  LTParameterAssert(nonNegativeNumbers.contains(lengthOfStartTapering),
                    @"Invalid length of start tapering: %g", lengthOfStartTapering);
  LTParameterAssert(nonNegativeNumbers.contains(lengthOfEndTapering),
                    @"Invalid length of end tapering: %g", lengthOfEndTapering);
  lt::Interval<CGFloat> openZeroOneRange =
      lt::Interval<CGFloat>({0, 1}, lt::Interval<CGFloat>::EndpointInclusion::Open,
                            lt::Interval<CGFloat>::EndpointInclusion::Closed);
  LTParameterAssert(openZeroOneRange.contains(taperingExponent), @"Invalid tapering exponent: %g",
                    taperingExponent);
  LTParameterAssert(openZeroOneRange.contains(minimumTaperingScaleFactor),
                    @"Invalid minimum tapering scale factor: %g", minimumTaperingScaleFactor);
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
      self.distance == model.distance && self.angle == model.angle && self.scale == model.scale &&
      self.lengthOfStartTapering == model.lengthOfStartTapering &&
      self.lengthOfEndTapering == model.lengthOfEndTapering &&
      self.taperingExponent == model.taperingExponent &&
      self.minimumTaperingScaleFactor == model.minimumTaperingScaleFactor;
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
#pragma mark Copying
#pragma mark -

- (instancetype)copyWithGeometryProviderModel:(id<DVNGeometryProviderModel>)geometryProviderModel
                                  randomState:(LTRandomState *)randomState {
  return [[[self class] alloc] initWithGeometryProviderModel:geometryProviderModel
                                                 randomState:randomState count:self.count
                                                    distance:self.distance angle:self.angle
                                                       scale:self.scale
                                       lengthOfStartTapering:self.lengthOfStartTapering
                                         lengthOfEndTapering:self.lengthOfEndTapering
                                            taperingExponent:self.taperingExponent
                                  minimumTaperingScaleFactor:self.minimumTaperingScaleFactor];
}

#pragma mark -
#pragma mark DVNGeometryProviderModel
#pragma mark -

- (id<DVNGeometryProvider>)provider {
  id<DVNGeometryProvider> provider = [self.geometryProviderModel provider];
  return [[DVNScatteredGeometryProvider alloc] initWithGeometryProvider:provider model:self];
}

@end

NS_ASSUME_NONNULL_END
