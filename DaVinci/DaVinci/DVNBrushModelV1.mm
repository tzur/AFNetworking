// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushModelV1.h"

#import <LTEngine/NSValueTransformer+LTEngine.h>

#import "DVNBlendMode.h"
#import "DVNBrushModelVersion.h"

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
      @instanceKeypath(DVNBrushModelV1, randomInitialSeed): @"randomInitialSeed",
      @instanceKeypath(DVNBrushModelV1, initialSeed): @"initialSeed",
      @instanceKeypath(DVNBrushModelV1, spacing): @"spacing",
      @instanceKeypath(DVNBrushModelV1, numberOfSamplesPerSequence): @"numberOfSamplesPerSequence",
      @instanceKeypath(DVNBrushModelV1, sequenceDistance): @"sequenceDistance",
      @instanceKeypath(DVNBrushModelV1, countRange): @"countRange",
      @instanceKeypath(DVNBrushModelV1, distanceJitterFactorRange): @"distanceJitterFactorRange",
      @instanceKeypath(DVNBrushModelV1, angleRange): @"angleRange",
      @instanceKeypath(DVNBrushModelV1, scaleJitterRange): @"scaleJitterRange",
      @instanceKeypath(DVNBrushModelV1, taperingLengths): @"taperingLengths",
      @instanceKeypath(DVNBrushModelV1, minimumTaperingScaleFactor): @"minimumTaperingScaleFactor",
      @instanceKeypath(DVNBrushModelV1, taperingExponent): @"taperingExponent",
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
#pragma mark Public API
#pragma mark -

+ (NSArray<NSString *> *)imageURLPropertyKeys {
  return @[@instanceKeypath(DVNBrushModelV1, sourceImageURL),
           @instanceKeypath(DVNBrushModelV1, maskImageURL),
           @instanceKeypath(DVNBrushModelV1, edgeAvoidanceGuideImageURL)];
}

@end

NS_ASSUME_NONNULL_END
