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

/// Heuristic value determining the maximum deviation of the required tapering scale factor and the
/// one computed while approximating the parametric factor required for performing end tapering.
static const CGFloat kMaximumAllowedTaperingScaleDeviation = 1e-3;

/// Heuristic value determining the maximum number of iterations to be used for approximating the
/// parametric factor required for performing end tapering.
static const NSUInteger kNumberOfIterationsForFactorApproximation = 10;

static CGFloat DVNApproximateFactorForTaperingScale(CGFloat taperingScale, CGFloat polynomialFactor,
                                                    lt::Interval<CGFloat> taperingScaleFactors) {
  CGFloat parametricValue = *taperingScaleFactors.parametricValue(taperingScale);
  CGFloat scale = DVNTaperingScale(parametricValue, polynomialFactor, taperingScaleFactors);

  // Perform binary search. This is possible since the Bernstein polynomial used in the
  // \c DVNTaperingScale computation is convex for factors between 0 and 1.

  CGFloat top = 1;
  CGFloat bottom = 0;
  for (NSUInteger i = 0; std::abs(scale - taperingScale) > kMaximumAllowedTaperingScaleDeviation &&
       i < kNumberOfIterationsForFactorApproximation; ++i) {
    if (scale < taperingScale) {
      bottom = parametricValue;
    } else {
      top = parametricValue;
    }
    parametricValue = (bottom + top) / 2;
    scale = DVNTaperingScale(parametricValue, polynomialFactor, taperingScaleFactors);
  }

  return parametricValue;
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

static lt::Quad DVNRandomlyTransformedQuadFromQuad(lt::Quad quad, CGFloat taperingScaleFactor,
                                                   lt::Interval<CGFloat> distanceRange,
                                                   lt::Interval<CGFloat> angleRange,
                                                   lt::Interval<CGFloat> scaleRange,
                                                   LTRandom *random) {
  CGFloat distanceLength = [random randomDoubleBetweenMin:distanceRange.inf()
                                                      max:distanceRange.sup()];
  CGPoint distance = CGPoint(LTVector2::angle([random randomDoubleBetweenMin:0 max:M_PI * 2]) *
                             distanceLength) * taperingScaleFactor;
  CGFloat angle = [random randomDoubleBetweenMin:angleRange.inf() max:angleRange.sup()];
  CGFloat scale = [random randomDoubleBetweenMin:scaleRange.inf() max:scaleRange.sup()] *
      taperingScaleFactor;
  CGPoint center = quad.center();

  // For increased performance, explicitly compute
  // <tt>quad.rotatedAroundPoint(angle, center).scaledBy(scale).translatedBy(distance)</tt>.
  CGFloat scaledCos = scale * std::cos(angle);
  CGFloat scaledSin = scale * std::sin(angle);
  CGAffineTransform transform =
      CGAffineTransformMake(scaledCos, scaledSin, -scaledSin, scaledCos,
                            (1 - scaledCos) * center.x + scaledSin * center.y + distance.x,
                            -scaledSin * center.x + (1 - scaledCos) * center.y + distance.y);
  return quad.transformedBy(transform);
}

- (dvn::GeometryValues)valuesFromSamples:(id<LTSampleValues>)samples end:(BOOL)end {
  dvn::GeometryValues values = [self.geometryProvider valuesFromSamples:samples end:end];
  samples = values.samples();

  if (!samples.sampledParametricValues.size()) {
    return dvn::GeometryValues();
  }

  const std::vector<lt::Quad> &originalQuads = values.quads();
  std::vector<lt::Quad> quads;
  quads.reserve(originalQuads.size());
  std::vector<NSUInteger> indices;
  indices.reserve(originalQuads.size());

  CGFloats sampledParametricValues = samples.sampledParametricValues;
  CGFloat minParametricValue = sampledParametricValues.front();
  CGFloat maxParametricValue = sampledParametricValues.back();
  CGFloat desiredLengthOfStartTapering = self.model.lengthOfStartTapering;
  CGFloat desiredLengthOfEndTapering = self.model.lengthOfEndTapering;
  CGFloat actualLengthOfStartTapering = desiredLengthOfStartTapering;
  CGFloat actualLengthOfEndTapering = std::min(maxParametricValue - minParametricValue,
                                               desiredLengthOfEndTapering);
  CGFloat startTaperingFactor = self.model.startTaperingFactor;
  CGFloat endTaperingFactor = self.model.endTaperingFactor;
  lt::Interval<CGFloat> taperingScaleFactors = self.taperingScaleFactors;
  CGFloat endTaperingInterpolationFactor = 1;

  // If the desired start tapering has not been performed fully but this is the final computation
  // of values, the actual length of start tapering must be adjusted in order to guarantee a
  // visually pleasing tapering behavior.
  CGFloat totalDesiredTaperingLength = desiredLengthOfStartTapering + desiredLengthOfEndTapering;

  if (self.performsTapering && end && desiredLengthOfStartTapering > 0 &&
      minParametricValue < desiredLengthOfStartTapering &&
      maxParametricValue < totalDesiredTaperingLength) {
    CGFloat factor = desiredLengthOfStartTapering / totalDesiredTaperingLength;
    // Ensure that start tapering is a) at least as long as the parametric range already processed,
    // b) at most as long as the desired start tapering, and has a length relative to the ratio
    // between the start and end tapering lengths.
    actualLengthOfStartTapering =
        std::max(minParametricValue,
                 std::min(desiredLengthOfStartTapering, factor * maxParametricValue));
    actualLengthOfEndTapering = maxParametricValue - actualLengthOfStartTapering;

    if (actualLengthOfEndTapering > 0 &&
        actualLengthOfStartTapering < desiredLengthOfStartTapering) {
      // If the actual start tapering length is smaller than the desired start tapering length, the
      // \c taperingScaleFactors will only be used to compute scale factors up to a parametric value
      // smaller than \c 1. Hence, the corresponding parametric value must be computed for the
      // corresponding end tapering computations.
      CGFloat maximumTaperingScale =
          DVNTaperingScale(actualLengthOfStartTapering / desiredLengthOfStartTapering,
                           startTaperingFactor, taperingScaleFactors);
      endTaperingInterpolationFactor = DVNApproximateFactorForTaperingScale(maximumTaperingScale,
                                                                            endTaperingFactor,
                                                                            taperingScaleFactors);
    }
  }

  lt::Interval<int> countRange = (lt::Interval<int>)self.model.count.closed();
  lt::Interval<CGFloat> distanceRange = self.model.distance.closed();
  lt::Interval<CGFloat> angleRange = self.model.angle.closed();
  lt::Interval<CGFloat> scaleRange = self.model.scale.closed();
  LTRandom *random = self.random;

  for (NSUInteger i = 0; i < sampledParametricValues.size(); ++i) {
    NSUInteger count = [random randomIntegerBetweenMin:countRange.inf() max:countRange.sup()];
    CGFloat taperingScaleFactor = 1;

    if (self.performsTapering) {
      CGFloat parametricValue = sampledParametricValues[i];
      if (parametricValue < actualLengthOfStartTapering) {
        taperingScaleFactor = DVNTaperingScale(parametricValue / desiredLengthOfStartTapering,
                                               startTaperingFactor, taperingScaleFactors);
      } else if (end) {
        CGFloat lengthToEnd = maxParametricValue - parametricValue;
        CGFloat factor = lengthToEnd || actualLengthOfEndTapering ?
            lengthToEnd / actualLengthOfEndTapering : 0;
        taperingScaleFactor = lengthToEnd > actualLengthOfEndTapering ? 1 :
            DVNTaperingScale(factor * endTaperingInterpolationFactor, endTaperingFactor,
                             taperingScaleFactors);
      }
    }

    lt::Quad quad = originalQuads[i];
    NSUInteger index = values.indices()[i];

    for (NSUInteger j = 0; j < count; ++j) {
      quads.push_back(DVNRandomlyTransformedQuadFromQuad(quad, taperingScaleFactor, distanceRange,
                                                         angleRange, scaleRange, random));
      indices.push_back(index);
    }
  }
  return dvn::GeometryValues(quads, indices, samples);
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
