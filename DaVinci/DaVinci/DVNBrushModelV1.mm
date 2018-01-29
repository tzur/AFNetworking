// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushModelV1.h"

#import <LTEngine/NSValueTransformer+LTEngine.h>

#import "DVNBlendMode.h"
#import "DVNBrushModelVersion.h"

NS_ASSUME_NONNULL_BEGIN

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
      @instanceKeypath(DVNBrushModelV1, minCount): @"minCount",
      @instanceKeypath(DVNBrushModelV1, maxCount): @"maxCount",
      @instanceKeypath(DVNBrushModelV1, minDistanceJitterFactor): @"minDistanceJitterFactor",
      @instanceKeypath(DVNBrushModelV1, maxDistanceJitterFactor): @"maxDistanceJitterFactor",
      @instanceKeypath(DVNBrushModelV1, minAngle): @"minAngle",
      @instanceKeypath(DVNBrushModelV1, maxAngle): @"maxAngle",
      @instanceKeypath(DVNBrushModelV1, minScaleJitter): @"minScaleJitter",
      @instanceKeypath(DVNBrushModelV1, maxScaleJitter): @"maxScaleJitter",
      @instanceKeypath(DVNBrushModelV1, lengthOfStartTapering): @"lengthOfStartTapering",
      @instanceKeypath(DVNBrushModelV1, lengthOfEndTapering): @"lengthOfEndTapering",
      @instanceKeypath(DVNBrushModelV1, minimumTaperingScaleFactor): @"minimumTaperingScaleFactor",
      @instanceKeypath(DVNBrushModelV1, taperingExponent): @"taperingExponent",
      @instanceKeypath(DVNBrushModelV1, flow): @"flow",
      @instanceKeypath(DVNBrushModelV1, minFlow): @"minFlow",
      @instanceKeypath(DVNBrushModelV1, maxFlow): @"maxFlow",
      @instanceKeypath(DVNBrushModelV1, flowExponent): @"flowExponent",
      @instanceKeypath(DVNBrushModelV1, color): @"color",
      @instanceKeypath(DVNBrushModelV1, brightnessJitter): @"brightnessJitter",
      @instanceKeypath(DVNBrushModelV1, hueJitter): @"hueJitter",
      @instanceKeypath(DVNBrushModelV1, saturationJitter): @"saturationJitter",
      @instanceKeypath(DVNBrushModelV1, brushTipImageURL): @"brushTipImageURL",
      @instanceKeypath(DVNBrushModelV1, brushTipImageGridSize): @"brushTipImageGridSize",
      @instanceKeypath(DVNBrushModelV1, overlayImageURL): @"overlayImageURL",
      @instanceKeypath(DVNBrushModelV1, blendMode): @"blendMode",
      @instanceKeypath(DVNBrushModelV1, edgeAvoidance): @"edgeAvoidance",
      @instanceKeypath(DVNBrushModelV1, edgeAvoidanceSamplingOffset): @"edgeAvoidanceSamplingOffset"
    }];

    mapping = [dictionary copy];
  });
  return mapping;
}

+ (NSValueTransformer *)colorJSONTransformer {
  return [NSValueTransformer valueTransformerForName:kLTVector3ValueTransformer];
}

+ (NSValueTransformer *)brushTipImageURLJSONTransformer {
  return [NSValueTransformer valueTransformerForName:kLTURLValueTransformer];
}

+ (NSValueTransformer *)brushTipImageGridSizeJSONTransformer {
  return [NSValueTransformer valueTransformerForName:kLTVector2ValueTransformer];
}

+ (NSValueTransformer *)overlayImageURLJSONTransformer {
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

#pragma mark -
#pragma mark Public API
#pragma mark -

+ (NSArray<NSString *> *)imageURLPropertyKeys {
  return @[@instanceKeypath(DVNBrushModelV1, brushTipImageURL),
           @instanceKeypath(DVNBrushModelV1, overlayImageURL)];
}

@end

NS_ASSUME_NONNULL_END
