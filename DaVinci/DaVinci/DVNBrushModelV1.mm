// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushModelV1.h"

#import <LTEngine/LTTexture.h>
#import <LTEngine/NSValue+LTInterval.h>
#import <LTEngine/NSValueTransformer+LTEngine.h>

#import "DVNBlendMode.h"
#import "DVNBrushModelVersion.h"
#import "DVNPropertyMacros.h"

NS_ASSUME_NONNULL_BEGIN

LTEnumImplement(NSUInteger, DVNSourceSamplingMode,
  DVNSourceSamplingModeFixed,
  DVNSourceSamplingModeQuadCenter,
  DVNSourceSamplingModeSubimage
);

@implementation DVNBrushModelV1

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  if (self = [super init]) {
    _color = LTVector3::null();
    _brushTipImageGridSize = LTVector2::null();
  }
  return self;
}

#pragma mark -
#pragma mark MTLJSONSerializing
#pragma mark -

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  static NSDictionary<NSString *, NSString *> *mapping;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSMutableDictionary<NSString *, NSString *> *dictionary =
        [[super JSONKeyPathsByPropertyKey] mutableCopy];
    [dictionary addEntriesFromDictionary:@{
      @instanceKeypath(DVNBrushModelV1, spacing): @"spacing",
      @instanceKeypath(DVNBrushModelV1, numberOfSamplesPerSequence): @"numberOfSamplesPerSequence",
      @instanceKeypath(DVNBrushModelV1, sequenceDistance): @"sequenceDistance",
      @instanceKeypath(DVNBrushModelV1, countRange): @"countRange",
      @instanceKeypath(DVNBrushModelV1, rotatedWithSplineDirection): @"rotatedWithSplineDirection",
      @instanceKeypath(DVNBrushModelV1, distanceJitterFactorRange): @"distanceJitterFactorRange",
      @instanceKeypath(DVNBrushModelV1, angleRange): @"angleRange",
      @instanceKeypath(DVNBrushModelV1, scaleJitterRange): @"scaleJitterRange",
      @instanceKeypath(DVNBrushModelV1, taperingLengths): @"taperingLengths",
      @instanceKeypath(DVNBrushModelV1, minimumTaperingScaleFactor): @"minimumTaperingScaleFactor",
      @instanceKeypath(DVNBrushModelV1, taperingFactors): @"taperingFactors",
      @instanceKeypath(DVNBrushModelV1, speedBasedTaperingFactor): @"speedBasedTaperingFactor",
      @instanceKeypath(DVNBrushModelV1, flow): @"flow",
      @instanceKeypath(DVNBrushModelV1, flowRange): @"flowRange",
      @instanceKeypath(DVNBrushModelV1, flowExponent): @"flowExponent",
      @instanceKeypath(DVNBrushModelV1, color): @"color",
      @instanceKeypath(DVNBrushModelV1, brightnessJitter): @"brightnessJitter",
      @instanceKeypath(DVNBrushModelV1, hueJitter): @"hueJitter",
      @instanceKeypath(DVNBrushModelV1, saturationJitter): @"saturationJitter",
      @instanceKeypath(DVNBrushModelV1, sourceSamplingMode): @"sourceSamplingMode",
      @instanceKeypath(DVNBrushModelV1, brushTipImageGridSize): @"brushTipImageGridSize",
      @instanceKeypath(DVNBrushModelV1, sourceImageURL): @"sourceImageURL",
      @instanceKeypath(DVNBrushModelV1, sourceImageIsNonPremultiplied):
          @"sourceImageIsNonPremultiplied",
      @instanceKeypath(DVNBrushModelV1, maskImageURL): @"maskImageURL",
      @instanceKeypath(DVNBrushModelV1, blendMode): @"blendMode",
      @instanceKeypath(DVNBrushModelV1, edgeAvoidance): @"edgeAvoidance",
      @instanceKeypath(DVNBrushModelV1, edgeAvoidanceGuideImageURL): @"edgeAvoidanceGuideImageURL",
      @instanceKeypath(DVNBrushModelV1, edgeAvoidanceSamplingOffset): @"edgeAvoidanceSamplingOffset"
    }];

    mapping = [dictionary copy];
  });
  return mapping;
}

+ (NSValueTransformer *)countRangeJSONTransformer {
  return [NSValueTransformer valueTransformerForName:kLTNSUIntegerIntervalValueTransformer];
}

+ (NSValueTransformer *)distanceJitterFactorRangeJSONTransformer {
  return [NSValueTransformer valueTransformerForName:kLTCGFloatIntervalValueTransformer];
}

+ (NSValueTransformer *)angleRangeJSONTransformer {
  return [NSValueTransformer valueTransformerForName:kLTCGFloatIntervalValueTransformer];
}

+ (NSValueTransformer *)scaleJitterRangeJSONTransformer {
  return [NSValueTransformer valueTransformerForName:kLTCGFloatIntervalValueTransformer];
}

+ (NSValueTransformer *)taperingLengthsJSONTransformer {
  return [NSValueTransformer valueTransformerForName:kLTVector2ValueTransformer];
}

+ (NSValueTransformer *)taperingFactorsJSONTransformer {
  return [NSValueTransformer valueTransformerForName:kLTVector2ValueTransformer];
}

+ (NSValueTransformer *)flowRangeJSONTransformer {
  return [NSValueTransformer valueTransformerForName:kLTCGFloatIntervalValueTransformer];
}

+ (NSValueTransformer *)colorJSONTransformer {
  return [NSValueTransformer valueTransformerForName:kLTVector3ValueTransformer];
}

/// Mapping of \c DVNSourceSamplingMode instances to the corresponding strings used for
/// serialization.
static NSDictionary<id<LTEnum>, NSString *> * const kSourceSamplingModeMapping = @{
  $(DVNSourceSamplingModeFixed): @"fixed",
  $(DVNSourceSamplingModeQuadCenter): @"center",
  $(DVNSourceSamplingModeSubimage): @"subimage"
};

+ (NSValueTransformer *)sourceSamplingModeJSONTransformer {
  return [NSValueTransformer lt_enumTransformerWithMap:kSourceSamplingModeMapping];
}

+ (NSValueTransformer *)brushTipImageGridSizeJSONTransformer {
  return [NSValueTransformer valueTransformerForName:kLTVector2ValueTransformer];
}

+ (NSValueTransformer *)sourceImageURLJSONTransformer {
  return [NSValueTransformer valueTransformerForName:kLTURLValueTransformer];
}

+ (NSValueTransformer *)maskImageURLJSONTransformer {
  return [NSValueTransformer valueTransformerForName:kLTURLValueTransformer];
}

/// Mapping of \c DVNBlendMode instances to the corresponding strings used for serialization.
static NSDictionary<id<LTEnum>, NSString *> * const kBlendModeMapping = @{
  $(DVNBlendModeNormal): @"normal",
  $(DVNBlendModeDarken): @"darken",
  $(DVNBlendModeMultiply): @"multiply",
  $(DVNBlendModeHardLight): @"hardLight",
  $(DVNBlendModeSoftLight): @"softLight",
  $(DVNBlendModeLighten): @"lighten",
  $(DVNBlendModeScreen): @"screen",
  $(DVNBlendModeColorBurn): @"burn",
  $(DVNBlendModeOverlay): @"overlay",
  $(DVNBlendModePlusLighter): @"lighter",
  $(DVNBlendModePlusDarker): @"darker",
  $(DVNBlendModeSubtract): @"subtract",
  $(DVNBlendModeOpaqueSource): @"opaqueSource",
  $(DVNBlendModeOpaqueDestination): @"opaqueDestination"
};

+ (NSValueTransformer *)blendModeJSONTransformer {
  return [NSValueTransformer lt_enumTransformerWithMap:kBlendModeMapping];
}

+ (NSValueTransformer *)edgeAvoidanceGuideImageURLJSONTransformer {
  return [NSValueTransformer valueTransformerForName:kLTURLValueTransformer];
}

#pragma mark -
#pragma mark Public API - Copying
#pragma mark -

- (instancetype)copyWithSpacing:(CGFloat)spacing {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:@(spacing) forKey:@keypath(model, spacing)];
  return model;
}

- (instancetype)copyWithNumberOfSamplesPerSequence:(NSUInteger)numberOfSamplesPerSequence {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:@(numberOfSamplesPerSequence) forKey:@keypath(model, numberOfSamplesPerSequence)];
  return model;
}

- (instancetype)copyWithSequenceDistance:(CGFloat)sequenceDistance {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:@(sequenceDistance) forKey:@keypath(model, sequenceDistance)];
  return model;
}

- (instancetype)copyWithCountRange:(lt::Interval<NSUInteger>)countRange {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:[NSValue valueWithLTNSUIntegerInterval:countRange]
           forKey:@keypath(model, countRange)];
  return model;
}

- (instancetype)copyWithRotatedWithSplineDirection:(BOOL)rotatedWithSplineDirection {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:@(rotatedWithSplineDirection) forKey:@keypath(model, rotatedWithSplineDirection)];
  return model;
}

- (instancetype)copyWithDistanceJitterFactorRange:(lt::Interval<CGFloat>)distanceJitterFactorRange {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:[NSValue valueWithLTCGFloatInterval:distanceJitterFactorRange]
           forKey:@keypath(model, distanceJitterFactorRange)];
  return model;
}

- (instancetype)copyWithAngleRange:(lt::Interval<CGFloat>)angleRange {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:[NSValue valueWithLTCGFloatInterval:angleRange]
           forKey:@keypath(model, angleRange)];
  return model;
}

- (instancetype)copyWithScaleJitterRange:(lt::Interval<CGFloat>)scaleJitterRange {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:[NSValue valueWithLTCGFloatInterval:scaleJitterRange]
           forKey:@keypath(model, scaleJitterRange)];
  return model;
}

- (instancetype)copyWithTaperingLengths:(LTVector2)taperingLengths {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:$(taperingLengths) forKey:@keypath(model, taperingLengths)];
  return model;
}

- (instancetype)copyWithMinimumTaperingScaleFactor:(CGFloat)minimumTaperingScaleFactor {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:@(minimumTaperingScaleFactor) forKey:@keypath(model, minimumTaperingScaleFactor)];
  return model;
}

- (instancetype)copyWithTaperingFactors:(LTVector2)taperingFactors {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:$(taperingFactors) forKey:@keypath(model, taperingFactors)];
  return model;
}

- (instancetype)copyWithSpeedBasedTaperingFactor:(CGFloat)speedBasedTaperingFactor {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:@(speedBasedTaperingFactor) forKey:@keypath(model, speedBasedTaperingFactor)];
  return model;
}

- (instancetype)copyWithFlow:(CGFloat)flow {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:@(model.flowRange.clamp(flow).value_or(model.flowRange.inf()))
           forKey:@keypath(model, flow)];
  return model;
}

- (instancetype)copyWithFlowExponent:(CGFloat)flowExponent {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:@(flowExponent) forKey:@keypath(model, flowExponent)];
  return model;
}

- (instancetype)copyWithColor:(LTVector3)color {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:$(std::clamp(color, 0, 1)) forKey:@keypath(model, color)];
  return model;
}

- (instancetype)copyWithBrightnessJitter:(CGFloat)brightnessJitter {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:@(brightnessJitter) forKey:@keypath(model, brightnessJitter)];
  return model;
}

- (instancetype)copyWithHueJitter:(CGFloat)hueJitter {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:@(hueJitter) forKey:@keypath(model, hueJitter)];
  return model;
}

- (instancetype)copyWithSaturationJitter:(CGFloat)saturationJitter {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:@(saturationJitter) forKey:@keypath(model, saturationJitter)];
  return model;
}

- (instancetype)copyWithSourceSamplingMode:(DVNSourceSamplingMode *)sourceSamplingMode {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:sourceSamplingMode forKey:@keypath(model, sourceSamplingMode)];
  return model;
}

- (instancetype)copyWithBrushTipImageGridSize:(LTVector2)brushTipImageGridSize {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:$(brushTipImageGridSize) forKey:@keypath(model, brushTipImageGridSize)];
  return model;
}

- (instancetype)copyWithSourceImageURL:(NSURL *)sourceImageURL {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:sourceImageURL forKey:@keypath(model, sourceImageURL)];
  return model;
}

- (instancetype)copyWithSourceImageIsNonPremultiplied:(BOOL)sourceImageIsNonPremultiplied {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:@(sourceImageIsNonPremultiplied)
           forKey:@keypath(model, sourceImageIsNonPremultiplied)];
  return model;
}

- (instancetype)copyWithMaskImageURL:(NSURL *)maskImageURL {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:maskImageURL forKey:@keypath(model, maskImageURL)];
  return model;
}

- (instancetype)copyWithBlendMode:(DVNBlendMode *)blendMode {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:blendMode forKey:@keypath(model, blendMode)];
  return model;
}

- (instancetype)copyWithEdgeAvoidance:(CGFloat)edgeAvoidance {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:@(edgeAvoidance) forKey:@keypath(model, edgeAvoidance)];
  return model;
}

- (instancetype)copyWithEdgeAvoidanceGuideImageURL:(NSURL *)edgeAvoidanceGuideImageURL {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:edgeAvoidanceGuideImageURL forKey:@keypath(model, edgeAvoidanceGuideImageURL)];
  return model;
}

- (instancetype)copyWithEdgeAvoidanceSamplingOffset:(CGFloat)edgeAvoidanceSamplingOffset {
  DVNBrushModelV1 *model = [self copy];
  [model setValue:@(edgeAvoidanceSamplingOffset)
           forKey:@keypath(model, edgeAvoidanceSamplingOffset)];
  return model;
}

#pragma mark -
#pragma mark Public API - Texture Mapping
#pragma mark -

- (BOOL)isValidTextureMapping:(NSDictionary<NSString *, LTTexture *> *)textureMapping {
  return [super isValidTextureMapping:textureMapping] &&
      textureMapping[@keypath(self, sourceImageURL)] &&
      textureMapping[@keypath(self, maskImageURL)] &&
      ([self.edgeAvoidanceGuideImageURL.absoluteString isEqualToString:@""] ||
       textureMapping[@keypath(self, edgeAvoidanceGuideImageURL)]);
}

#pragma mark -
#pragma mark Public API - Image URL Property Keys
#pragma mark -

+ (NSArray<NSString *> *)imageURLPropertyKeys {
  return @[@instanceKeypath(DVNBrushModelV1, sourceImageURL),
           @instanceKeypath(DVNBrushModelV1, maskImageURL),
           @instanceKeypath(DVNBrushModelV1, edgeAvoidanceGuideImageURL)];
}

DVNClosedRangeClassProperty(CGFloat, allowedSpacing, AllowedSpacing, 0.001,
                            std::numeric_limits<CGFloat>::max());

- (void)setSpacing:(CGFloat)spacing {
  _spacing = *[[self class] allowedSpacingRange].clamp(spacing);
}

DVNClosedRangeClassProperty(NSUInteger, allowedNumberOfSamplesPerSequence,
                            AllowedNumberOfSamplesPerSequence, 1, NSUIntegerMax);

- (void)setNumberOfSamplesPerSequence:(NSUInteger)numberOfSamplesPerSequence {
  _numberOfSamplesPerSequence =
      *[[self class] allowedNumberOfSamplesPerSequenceRange].clamp(numberOfSamplesPerSequence);
}

DVNClosedRangeClassProperty(CGFloat, allowedSequenceDistance, AllowedSequenceDistance, 0.001,
                            std::numeric_limits<CGFloat>::max());

- (void)setSequenceDistance:(CGFloat)sequenceDistance {
  _sequenceDistance = *[[self class] allowedSequenceDistanceRange].clamp(sequenceDistance);
}

DVNClosedRangeClassProperty(NSUInteger, allowedCount, AllowedCount, 0, NSUIntegerMax);

- (void)setCountRange:(lt::Interval<NSUInteger>)countRange {
  _countRange = *countRange.clampedTo([[self class] allowedCountRange]);
}

DVNClosedRangeClassProperty(CGFloat, allowedDistanceJitterFactor, AllowedDistanceJitterFactor, 0,
                            std::numeric_limits<CGFloat>::max());

- (void)setDistanceJitterFactorRange:(lt::Interval<CGFloat>)distanceJitterFactorRange {
  _distanceJitterFactorRange =
      *distanceJitterFactorRange.clampedTo([[self class] allowedDistanceJitterFactorRange]);
}

DVNClosedRangeClassProperty(CGFloat, allowedAngle, AllowedAngle, 0, 4 * M_PI);

- (void)setAngleRange:(lt::Interval<CGFloat>)angleRange {
  _angleRange = *angleRange.clampedTo([[self class] allowedAngleRange]);
}

DVNClosedRangeClassProperty(CGFloat, allowedScaleJitter, AllowedScaleJitter, 0,
                            std::numeric_limits<CGFloat>::max());

- (void)setScaleJitterRange:(lt::Interval<CGFloat>)scaleJitterRange {
  _scaleJitterRange = *scaleJitterRange.clampedTo([[self class] allowedScaleJitterRange]);
}

DVNClosedRangeClassProperty(float, allowedTaperingLength, AllowedTaperingLength, 0,
                            std::numeric_limits<float>::max());

- (void)setTaperingLengths:(LTVector2)taperingLengths {
  lt::Interval<float> range = [[self class] allowedTaperingLengthRange];
  _taperingLengths = std::clamp(taperingLengths, *range.min(), *range.max());
}

DVNLeftOpenRangeClassProperty(CGFloat, allowedMinimumTaperingScaleFactor,
                              AllowedMinimumTaperingScaleFactor, 0, 1);

- (void)setMinimumTaperingScaleFactor:(CGFloat)minimumTaperingScaleFactor {
  _minimumTaperingScaleFactor =
      *[[self class] allowedMinimumTaperingScaleFactorRange].clamp(minimumTaperingScaleFactor);
}

DVNClosedRangeClassProperty(float, allowedTaperingFactor, AllowedTaperingFactor, 0, 1);

- (void)setTaperingFactors:(LTVector2)taperingFactors {
  lt::Interval<float> range = [[self class] allowedTaperingFactorRange];
  _taperingFactors = std::clamp(taperingFactors, *range.min(), *range.max());
}

DVNClosedRangeClassProperty(float, allowedSpeedBasedTaperingFactor, AllowedSpeedBasedTaperingFactor,
                            -1, 1);

- (void)setSpeedBasedTaperingFactor:(float)speedBasedTaperingFactor {
  lt::Interval<float> range = [[self class] allowedSpeedBasedTaperingFactorRange];
  _speedBasedTaperingFactor = std::clamp(speedBasedTaperingFactor, *range.min(), *range.max());
}

DVNClosedRangeClassProperty(CGFloat, allowedFlow, AllowedFlow, 0, 1);

- (void)setFlow:(CGFloat)flow {
  _flow = *[[self class] allowedFlowRange].clamp(flow);
}

DVNLeftOpenRangeClassProperty(CGFloat, allowedFlowExponent, AllowedFlowExponent, 0, 20);

- (void)setFlowExponent:(CGFloat)flowExponent {
  _flowExponent = *[[self class] allowedFlowExponentRange].clamp(flowExponent);
}

DVNClosedRangeClassProperty(CGFloat, allowedBrightnessJitter, AllowedBrightnessJitter, 0, 1);

- (void)setBrightnessJitter:(CGFloat)brightnessJitter {
  _brightnessJitter = *[[self class] allowedBrightnessJitterRange].clamp(brightnessJitter);
}

DVNClosedRangeClassProperty(CGFloat, allowedHueJitter, AllowedHueJitter, 0, 1);

- (void)setHueJitter:(CGFloat)hueJitter {
  _hueJitter = *[[self class] allowedHueJitterRange].clamp(hueJitter);
}

DVNClosedRangeClassProperty(CGFloat, allowedSaturationJitter, AllowedSaturationJitter, 0, 1);

- (void)setSaturationJitter:(CGFloat)saturationJitter {
  _saturationJitter = *[[self class] allowedSaturationJitterRange].clamp(saturationJitter);
}

- (void)setBrushTipImageGridSize:(LTVector2)brushTipImageGridSize {
  lt::Interval<NSUInteger> range = lt::Interval<NSUInteger>::positiveNumbers();
  _brushTipImageGridSize =
      LTVector2(*range.clamp(std::round(std::max<CGFloat>(brushTipImageGridSize.x, 0))),
                *range.clamp(std::round(std::max<CGFloat>(brushTipImageGridSize.y, 0))));
}

DVNClosedRangeClassProperty(CGFloat, allowedEdgeAvoidance, AllowedEdgeAvoidance, 0, 1);

- (void)setEdgeAvoidance:(CGFloat)edgeAvoidance {
  _edgeAvoidance = *[[self class] allowedEdgeAvoidanceRange].clamp(edgeAvoidance);
}

DVNClosedRangeClassProperty(CGFloat, allowedEdgeAvoidanceSamplingOffset,
                            AllowedEdgeAvoidanceSamplingOffset, 0,
                            std::numeric_limits<CGFloat>::max());

- (void)setEdgeAvoidanceSamplingOffset:(CGFloat)edgeAvoidanceSamplingOffset {
  _edgeAvoidanceSamplingOffset =
      *[[self class] allowedEdgeAvoidanceSamplingOffsetRange].clamp(edgeAvoidanceSamplingOffset);
}

@end

NS_ASSUME_NONNULL_END
