// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushModelV1.h"

#import <LTKit/NSArray+NSSet.h>

#import "DVNBlendMode.h"
#import "DVNBrushModelVersion+TestBrushModel.h"

#if !CGFLOAT_IS_DOUBLE
static NSDictionary *
    DVNDictionaryWithUpdatedCGFloatValues(NSDictionary<NSString *, id> *dictionary) {
  NSMutableDictionary *mutableDictionary = [dictionary mutableCopy];

  for (NSString *key in dictionary.allKeys) {
    if ([dictionary[key] isKindOfClass:[NSNumber class]]) {
      CGFloat value = [dictionary[key] CGFloatValue];
      mutableDictionary[key] = @(value);
    }
  }

  return [mutableDictionary copy];
}
#endif

SpecBegin(DVNBrushModelV1)

context(@"initialization", ^{
  __block NSDictionary *jsonDictionary;
  __block DVNBrushModelV1 *model;
  __block NSError *error;

  beforeEach(^{
    jsonDictionary = [$(DVNBrushModelVersionV1) JSONDictionaryOfTestBrushModel];
#if !CGFLOAT_IS_DOUBLE
    // Since NSJSONSerialization may use double instead of float for deserialization of JSON
    // dictionaries even if CGFloat is float, the NSNumber values of the dictionary have to be
    // converted explicitely to new NSNumber objects holding CGFloat values.
    jsonDictionary = DVNDictionaryWithUpdatedCGFloatValues(jsonDictionary);
#endif

    model = [MTLJSONAdapter modelOfClass:[DVNBrushModelV1 class] fromJSONDictionary:jsonDictionary
                                   error:&error];
  });

  context(@"deserialization", ^{
    it(@"should deserialize without an error", ^{
      expect(model).toNot.beNil();
      expect(error).to.beNil();
    });

    it(@"should deserialize with correct values", ^{
      // DVNBrushModel
      expect(model.version).to.equal($(DVNBrushModelVersionV1));
      expect(model.scaleRange == lt::Interval<CGFloat>({1.25, 1.75},
                                                       lt::Interval<CGFloat>::Open,
                                                       lt::Interval<CGFloat>::Closed))
          .to.beTruthy();
      expect(model.scale).to.equal(1.5);

      // DVNBrushModelV1
      expect(model.randomInitialSeed).to.beTruthy();
      expect(model.initialSeed).to.equal(7);
      expect(model.spacing).to.equal(0.015625);
      expect(model.numberOfSamplesPerSequence).to.equal(8);
      expect(model.sequenceDistance).to.equal(0.0195312);
      expect(model.countRange == lt::Interval<NSUInteger>({9, 10})).to.beTruthy();
      expect(model.distanceJitterFactorRange == lt::Interval<CGFloat>({0.0234375, 0.0273438},
                                                                      lt::Interval<CGFloat>::Closed,
                                                                      lt::Interval<CGFloat>::Open))
          .to.beTruthy();
      expect(model.angleRange == lt::Interval<CGFloat>({0.03125, 0.0351562},
                                                       lt::Interval<CGFloat>::Open,
                                                       lt::Interval<CGFloat>::Closed))
          .to.beTruthy();
      expect(model.scaleJitterRange == lt::Interval<CGFloat>({0.0390625, 2},
                                                             lt::Interval<CGFloat>::Open))
          .to.beTruthy();
      expect(model.taperingLengths).to.equal(LTVector2(0.046875, 0.0507812));
      expect(model.minimumTaperingScaleFactor).to.equal(0.0546875);
      expect(model.taperingFactors).to.equal(LTVector2(0.0585938, 0.0664062));
      expect(model.flowRange == lt::Interval<CGFloat>({0.0625, 0.0703125})).to.beTruthy();
      expect(model.flow).to.equal(0.0664062);
      expect(model.flowExponent).to.equal(0.0742188);
      expect(model.color).to.equal(LTVector3(0.88, 0, 0));
      expect(model.brightnessJitter).to.equal(0.078125);
      expect(model.hueJitter).to.equal(0.0820312);
      expect(model.saturationJitter).to.equal(0.0859375);
      expect(model.sourceSamplingMode).to.equal($(DVNSourceSamplingModeSubimage));
      expect(model.brushTipImageGridSize).to.equal(LTVector2(7, 8));
      expect(model.sourceImageURL).to.equal([NSURL URLWithString:@"image://source"]);
      expect(model.sourceImageIsNonPremultiplied).to.beTruthy();
      expect(model.maskImageURL).to.equal([NSURL URLWithString:@"image://mask"]);
      expect(model.blendMode).to.equal($(DVNBlendModeDarken));
      expect(model.edgeAvoidance).to.equal(0.0898438);
      expect(model.edgeAvoidanceGuideImageURL)
          .to.equal([NSURL URLWithString:@"image://edgeAvoidanceGuide"]);
      expect(model.edgeAvoidanceSamplingOffset).to.equal(0.0742188);
    });
  });

  context(@"serialization", ^{
    it(@"should serialize correctly", ^{
      expect([MTLJSONAdapter JSONDictionaryFromModel:model]).to.equal(jsonDictionary);
    });
  });
});

context(@"image URL property keys", ^{
  it(@"should return the correct property keys", ^{
    NSSet *expectedKeys = @[@instanceKeypath(DVNBrushModelV1, sourceImageURL),
                            @instanceKeypath(DVNBrushModelV1, maskImageURL),
                            @instanceKeypath(DVNBrushModelV1, edgeAvoidanceGuideImageURL)].lt_set;
    expect([DVNBrushModelV1 imageURLPropertyKeys].lt_set).to.equal(expectedKeys);
  });
});

context(@"allowed ranges", ^{
  static const CGFloat kCGFloatMax = std::numeric_limits<CGFloat>::max();
  static const NSUInteger kNSUIntegerMax = std::numeric_limits<NSUInteger>::max();

  it(@"should return the allowed scale range", ^{
    expect([DVNBrushModel allowedScaleRange] == lt::Interval<CGFloat>::oc({0, kCGFloatMax}))
        .to.beTruthy();
    expect([DVNBrushModelV1 allowedInitialSeedRange] ==
           lt::Interval<NSUInteger>({0, kNSUIntegerMax})).to.beTruthy();
    expect([DVNBrushModelV1 allowedSpacingRange] ==
           lt::Interval<CGFloat>({0.001, kCGFloatMax})).to.beTruthy();
    expect([DVNBrushModelV1 allowedNumberOfSamplesPerSequenceRange] ==
           lt::Interval<NSUInteger>({1, kNSUIntegerMax})).to.beTruthy();
    expect([DVNBrushModelV1 allowedSequenceDistanceRange] ==
           lt::Interval<CGFloat>({0.001, kCGFloatMax})).to.beTruthy();
    expect([DVNBrushModelV1 allowedCountRange] ==
           lt::Interval<NSUInteger>({0, kNSUIntegerMax})).to.beTruthy();
    expect([DVNBrushModelV1 allowedDistanceJitterFactorRange] ==
           lt::Interval<CGFloat>({0, kCGFloatMax})).to.beTruthy();
    expect([DVNBrushModelV1 allowedAngleRange] == lt::Interval<CGFloat>({0, 4 * M_PI}))
        .to.beTruthy();
    expect([DVNBrushModelV1 allowedScaleJitterRange] == lt::Interval<CGFloat>({0, kCGFloatMax}))
        .to.beTruthy();
    expect([DVNBrushModelV1 allowedTaperingLengthRange] == lt::Interval<CGFloat>({0, kCGFloatMax}))
        .to.beTruthy();
    expect([DVNBrushModelV1 allowedMinimumTaperingScaleFactorRange] ==
           lt::Interval<CGFloat>::oc({0, 1})).to.beTruthy();
    expect([DVNBrushModelV1 allowedTaperingFactorRange] == lt::Interval<CGFloat>({0, 1}))
        .to.beTruthy();
    expect([DVNBrushModelV1 allowedFlowRange] == lt::Interval<CGFloat>({0, 1})).to.beTruthy();
    expect([DVNBrushModelV1 allowedFlowExponentRange] == lt::Interval<CGFloat>::oc({0, 20}))
        .to.beTruthy();
    expect([DVNBrushModelV1 allowedBrightnessJitterRange] == lt::Interval<CGFloat>({0, 1}))
        .to.beTruthy();
    expect([DVNBrushModelV1 allowedHueJitterRange] == lt::Interval<CGFloat>({0, 1}))
        .to.beTruthy();
    expect([DVNBrushModelV1 allowedSaturationJitterRange] == lt::Interval<CGFloat>({0, 1}))
        .to.beTruthy();
    expect([DVNBrushModelV1 allowedEdgeAvoidanceRange] == lt::Interval<CGFloat>({0, 1}))
        .to.beTruthy();
    expect([DVNBrushModelV1 allowedEdgeAvoidanceSamplingOffsetRange] ==
           lt::Interval<CGFloat>({0, kCGFloatMax})).to.beTruthy();
  });
});

SpecEnd
