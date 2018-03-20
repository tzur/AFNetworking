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

static NSDictionary *DVNJSONDictionaryOfTestBrushModelV1() {
  NSDictionary *jsonDictionary = [$(DVNBrushModelVersionV1) JSONDictionaryOfTestBrushModel];
#if !CGFLOAT_IS_DOUBLE
    // Since NSJSONSerialization may use double instead of float for deserialization of JSON
    // dictionaries even if CGFloat is float, the NSNumber values of the dictionary have to be
    // converted explicitely to new NSNumber objects holding CGFloat values.
    jsonDictionary = DVNDictionaryWithUpdatedCGFloatValues(jsonDictionary);
#endif
  return jsonDictionary;
}

static NSArray<NSString *> *DVNPropertyKeys(Class classObject) {
  unsigned int count = 0;
  objc_property_t *properties = class_copyPropertyList(classObject, &count);
  if (!count) {
    return @[];
  }

  @onExit {
    free(properties);
  };

  NSMutableArray<NSString *> *propertyKeys = [NSMutableArray arrayWithCapacity:count];
  for (unsigned i = 0; i < count; ++i) {
    NSString *propertyName = @(property_getName(properties[i]));

    ext_propertyAttributes *attributes = ext_copyPropertyAttributes(properties[i]);
    @onExit {
      free(attributes);
    };

    if (attributes->ivar) {
      [propertyKeys addObject:propertyName];
    }
  }

  return propertyKeys;
}

SpecBegin(DVNBrushModelV1)

context(@"initialization", ^{
  __block NSDictionary *jsonDictionary;
  __block DVNBrushModelV1 *model;
  __block NSError *error;

  beforeEach(^{
    jsonDictionary = DVNJSONDictionaryOfTestBrushModelV1();
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
      expect(model.scaleRange == lt::Interval<CGFloat>::oc({1.25, 1.75})).to.beTruthy();
      expect(model.scale).to.equal(1.5);

      // DVNBrushModelV1
      expect(model.randomInitialSeed).to.beTruthy();
      expect(model.initialSeed).to.equal(7);
      expect(model.spacing).to.equal(0.015625);
      expect(model.numberOfSamplesPerSequence).to.equal(8);
      expect(model.sequenceDistance).to.equal(0.0195312);
      expect(model.countRange == lt::Interval<NSUInteger>({9, 10})).to.beTruthy();
      expect(model.distanceJitterFactorRange == lt::Interval<CGFloat>::co({0.0234375, 0.0273438}))
          .to.beTruthy();
      expect(model.angleRange == lt::Interval<CGFloat>::oc({0.03125, 0.0351562})).to.beTruthy();
      expect(model.scaleJitterRange == lt::Interval<CGFloat>::oo({0.0390625, 2})).to.beTruthy();
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

context(@"copy constructors", ^{
  __block DVNBrushModelV1 *model;

  beforeEach(^{
    NSDictionary *jsonDictionary = DVNJSONDictionaryOfTestBrushModelV1();
    model = [MTLJSONAdapter modelOfClass:[DVNBrushModelV1 class] fromJSONDictionary:jsonDictionary
                                   error:nil];
  });

  context(@"scale", ^{
    it(@"should return a copy scaled by a given scale", ^{
      DVNBrushModelV1 *scaledModel = [model scaledBy:2];
      expect(scaledModel.scale).to.equal(3);
      expect(scaledModel.scaleRange == lt::Interval<CGFloat>::oc({2.5, 3.5})).to.beTruthy();
      expect(scaledModel.spacing).to.equal(0.015625);
    });

    it(@"should return a copy with a given scale", ^{
      DVNBrushModelV1 *scaledModel = [model copyWithScale:1.375];
      expect(scaledModel.scale).to.equal(1.375);
      expect(scaledModel.scaleRange == lt::Interval<CGFloat>::oc({1.25, 1.75})).to.beTruthy();
      expect(scaledModel.spacing).to.equal(0.015625);
    });

    it(@"should return a copy with a given scale, clamped to the scale range", ^{
      DVNBrushModelV1 *scaledModel = [model copyWithScale:2];
      expect(scaledModel.scale).to.equal(1.75);
      expect(scaledModel.scaleRange == lt::Interval<CGFloat>::oc({1.25, 1.75})).to.beTruthy();
      expect(scaledModel.spacing).to.equal(0.015625);
    });
  });

  context(@"flow", ^{
    it(@"should return a copy with a given flow", ^{
      DVNBrushModelV1 *scaledModel = [model copyWithFlow:0.07];
      expect(scaledModel.flow).to.equal(0.07);
      expect(scaledModel.spacing).to.equal(0.015625);
    });

    it(@"should return a copy with a given flow, clamped to the flow range", ^{
      DVNBrushModelV1 *scaledModel = [model copyWithFlow:0];
      expect(scaledModel.flow).to.equal(0.0625);
      expect(scaledModel.spacing).to.equal(0.015625);
    });
  });

  context(@"edge avoidance", ^{
    it(@"should return a copy with a given edge avoidance", ^{
      DVNBrushModelV1 *scaledModel = [model copyWithEdgeAvoidance:0.5];
      expect(scaledModel.edgeAvoidance).to.equal(0.5);
      expect(scaledModel.spacing).to.equal(0.015625);
    });

    it(@"should return a copy with a given edge avoidance, clamped to the allowed range", ^{
      DVNBrushModelV1 *scaledModel = [model copyWithEdgeAvoidance:-1];
      expect(scaledModel.edgeAvoidance).to.equal(0);
      expect(scaledModel.spacing).to.equal(0.015625);
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

context(@"JSON serialization strings", ^{
  it(@"should provide serialization keys for all serializable properties", ^{
    NSMutableArray<NSString *> *propertyKeypaths =
        [DVNPropertyKeys([[DVNBrushModelV1 class] superclass]) mutableCopy];
    NSArray<NSString *> *propertyKeypathsV1 = DVNPropertyKeys([DVNBrushModelV1 class]);
    [propertyKeypaths addObjectsFromArray:propertyKeypathsV1];

    expect([[DVNBrushModelV1 JSONKeyPathsByPropertyKey] allKeys].lt_set)
        .to.equal(propertyKeypaths.lt_set);
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
