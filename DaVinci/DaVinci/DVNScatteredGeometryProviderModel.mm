// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNScatteredGeometryProviderModel.h"

#import <LTKit/LTRandom.h>

#import "DVNGeometryProvider.h"

NS_ASSUME_NONNULL_BEGIN

static CGFloat DVNTaperingScale(CGFloat factor, CGFloat polynomialFactor,
                                lt::Interval<CGFloat> taperingScaleFactors) {
  CGFloat t = factor;
  CGFloat t2 = t * t;
  CGFloat t3 = t2 * t;
  // Use the Bernstein polynomial originating from the cubic Bezier curve determined by control
  // points \c 0, \c polynomialFactor, \c 1, and \c 1.
  CGFloat normalizedScaleFactor = (3 * t3 - 6 * t2 + 3 * t) * polynomialFactor - 2 * t3 + 3 * t2;
  return *taperingScaleFactors.valueAt(normalizedScaleFactor);
}

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

/// Range of scale factors used for tapering.
@property (readonly, nonatomic) lt::Interval<CGFloat> taperingScaleFactors;

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
    _taperingScaleFactors = lt::Interval<CGFloat>({model.minimumTaperingScaleFactor, 1});
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
  CGFloat lengthOfStartTapering = self.model.lengthOfStartTapering;
  CGFloat startTaperingFactor = self.model.startTaperingFactor;
  CGFloat length = std::min(maxParametricValue - minParametricValue,
                            self.model.lengthOfEndTapering);
  CGFloat maximumTaperingScaleFactor = 1;

  if (end && lengthOfStartTapering) {
    CGFloat interpolationValue = std::min<CGFloat>(minParametricValue / lengthOfStartTapering, 1.0);
    maximumTaperingScaleFactor = DVNTaperingScale(interpolationValue, startTaperingFactor,
                                                  self.taperingScaleFactors);
  }

  for (NSUInteger i = 0; i < sampledParametricValues.size(); ++i) {
    lt::Interval<int> countRange = (lt::Interval<int>)self.model.count.closed();
    NSUInteger count = [self.random randomIntegerBetweenMin:countRange.inf() max:countRange.sup()];
    CGFloat taperingScaleFactor = 1;

    if (self.performsTapering) {
      CGFloat parametricValue = sampledParametricValues[i];
      if (!end && parametricValue / lengthOfStartTapering < 1) {
        taperingScaleFactor = DVNTaperingScale(parametricValue / lengthOfStartTapering,
                                               startTaperingFactor, self.taperingScaleFactors);
      } else if (end) {
        CGFloat lengthToEnd = maxParametricValue - parametricValue;
        CGFloat endTaperingScaleFactor = lengthToEnd > self.model.lengthOfEndTapering ?
            1 : DVNTaperingScale(lengthToEnd / length, self.model.endTaperingFactor,
                                 self.taperingScaleFactors);
        taperingScaleFactor = maximumTaperingScaleFactor * endTaperingScaleFactor;
      }
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
  lt::Interval<CGFloat> distanceRange = self.model.distance.closed();
  CGFloat distanceLength = [self.random randomDoubleBetweenMin:distanceRange.inf()
                                                           max:distanceRange.sup()];
  CGPoint distance = CGPoint(LTVector2::angle([self.random randomDoubleBetweenMin:0 max:M_PI * 2]) *
                             distanceLength);
  lt::Interval<CGFloat> angleRange = self.model.angle.closed();
  CGFloat angle = [self.random randomDoubleBetweenMin:angleRange.inf() max:angleRange.sup()];
  lt::Interval<CGFloat> scaleRange = self.model.scale.closed();
  CGFloat scale = [self.random randomDoubleBetweenMin:scaleRange.inf() max:scaleRange.sup()];
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
                       lengthOfStartTapering:0 lengthOfEndTapering:0 startTaperingFactor:1
                         endTaperingFactor:1 minimumTaperingScaleFactor:1];
}

- (instancetype)initWithGeometryProviderModel:(id<DVNGeometryProviderModel>)geometryProviderModel
                                  randomState:(LTRandomState *)randomState
                                        count:(lt::Interval<NSUInteger>)count
                                     distance:(lt::Interval<CGFloat>)distance
                                        angle:(lt::Interval<CGFloat>)angle
                                        scale:(lt::Interval<CGFloat>)scale
                        lengthOfStartTapering:(CGFloat)lengthOfStartTapering
                          lengthOfEndTapering:(CGFloat)lengthOfEndTapering
                          startTaperingFactor:(CGFloat)startTaperingFactor
                            endTaperingFactor:(CGFloat)endTaperingFactor
                   minimumTaperingScaleFactor:(CGFloat)minimumTaperingScaleFactor {
  [self validateDistance:distance angle:angle scale:scale
   lengthOfStartTapering:lengthOfStartTapering lengthOfEndTapering:lengthOfEndTapering
   startTaperingFactor:startTaperingFactor endTaperingFactor:endTaperingFactor
   minTaperingScaleFactor:minimumTaperingScaleFactor];

  if (self = [super init]) {
    _geometryProviderModel = geometryProviderModel;
    _randomState = randomState;
    _count = count;
    _distance = distance;
    _angle = angle;
    _scale = scale;
    _lengthOfStartTapering = lengthOfStartTapering;
    _lengthOfEndTapering = lengthOfEndTapering;
    _startTaperingFactor = startTaperingFactor;
    _endTaperingFactor = endTaperingFactor;
    _minimumTaperingScaleFactor = minimumTaperingScaleFactor;
  }
  return self;
}

- (void)validateDistance:(lt::Interval<CGFloat>)distance angle:(lt::Interval<CGFloat>)angle
                   scale:(lt::Interval<CGFloat>)scale
   lengthOfStartTapering:(CGFloat)lengthOfStartTapering
     lengthOfEndTapering:(CGFloat)lengthOfEndTapering
     startTaperingFactor:(CGFloat)startTaperingFactor endTaperingFactor:(CGFloat)endTaperingFactor
  minTaperingScaleFactor:(CGFloat)minTaperingScaleFactor {
  LTParameterAssert(distance.intersectionWith(lt::Interval<CGFloat>::nonNegativeNumbers()) ==
                    distance, @"Interval %@ outside valid distance interval ([0, CGFLOAT_MAX])",
                    distance.description());
  lt::Interval<CGFloat> validAngleInterval = lt::Interval<CGFloat>::co({0, 4 * M_PI});
  LTParameterAssert(angle.intersects(validAngleInterval),
                    @"Interval %@ outside valid angle interval ([0, 4 * PI])",
                    angle.description());
  LTParameterAssert(scale.intersectionWith(lt::Interval<CGFloat>::nonNegativeNumbers()) == scale,
                    @"Interval %@ outside valid scaling interval ((0, CGFLOAT_MAX])",
                    scale.description());
  LTParameterAssert(lt::Interval<CGFloat>::nonNegativeNumbers().contains(lengthOfStartTapering),
                    @"Invalid length of start tapering: %g", lengthOfStartTapering);
  LTParameterAssert(lt::Interval<CGFloat>::nonNegativeNumbers().contains(lengthOfEndTapering),
                    @"Invalid length of end tapering: %g", lengthOfEndTapering);
  LTParameterAssert(lt::Interval<CGFloat>::zeroToOne().contains(startTaperingFactor),
                    @"Invalid start tapering factor: %g", startTaperingFactor);
  LTParameterAssert(lt::Interval<CGFloat>::zeroToOne().contains(endTaperingFactor),
                    @"Invalid end tapering factor: %g", endTaperingFactor);
  LTParameterAssert(lt::Interval<CGFloat>::openZeroToClosedOne().contains(minTaperingScaleFactor),
                    @"Invalid minimum tapering scale factor: %g", minTaperingScaleFactor);
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
      self.startTaperingFactor == model.startTaperingFactor &&
      self.endTaperingFactor == model.endTaperingFactor &&
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
  lt::hash_combine(seed, self.lengthOfStartTapering);
  lt::hash_combine(seed, self.lengthOfEndTapering);
  lt::hash_combine(seed, self.startTaperingFactor);
  lt::hash_combine(seed, self.endTaperingFactor);
  lt::hash_combine(seed, self.minimumTaperingScaleFactor);
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
                                         startTaperingFactor:self.startTaperingFactor
                                           endTaperingFactor:self.endTaperingFactor
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
