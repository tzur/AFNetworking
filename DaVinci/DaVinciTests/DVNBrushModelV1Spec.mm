// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushModelV1.h"

#import <LTEngine/LTTexture.h>
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
      expect(model.splineSmoothness).to.equal(0.0898438);
      expect(model.spacing).to.equal(0.015625);
      expect(model.numberOfSamplesPerSequence).to.equal(8);
      expect(model.sequenceDistance).to.equal(0.0195312);
      expect(model.countRange == lt::Interval<NSUInteger>({9, 10})).to.beTruthy();
      expect(model.rotatedWithSplineDirection).to.beTruthy();
      expect(model.distanceJitterFactorRange == lt::Interval<CGFloat>::co({0.0234375, 0.0273438}))
          .to.beTruthy();
      expect(model.angleRange == lt::Interval<CGFloat>::oc({0.03125, 0.0351562})).to.beTruthy();
      expect(model.scaleJitterRange == lt::Interval<CGFloat>::oo({0.0390625, 2})).to.beTruthy();
      expect(model.taperingLengths).to.equal(LTVector2(0.046875, 0.0507812));
      expect(model.minimumTaperingScaleFactor).to.equal(0.0546875);
      expect(model.taperingFactors).to.equal(LTVector2(0.0585938, 0.0664062));
      expect(model.speedBasedTaperingFactor).to.equal(0.125);
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
      DVNBrushModelV1 *modelCopy = [model scaledBy:2];
      expect(modelCopy.scale).to.equal(3);
      expect(modelCopy.scaleRange == lt::Interval<CGFloat>::oc({2.5, 3.5})).to.beTruthy();
      expect(modelCopy.spacing).to.equal(0.015625);
    });

    it(@"should return a copy with given scale", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithScale:1.375];
      expect(modelCopy.scale).to.equal(1.375);
      expect(modelCopy.scaleRange == lt::Interval<CGFloat>::oc({1.25, 1.75})).to.beTruthy();
      expect(modelCopy.spacing).to.equal(0.015625);
    });

    it(@"should return a copy with given scale, clamped to the scale range", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithScale:2];
      expect(modelCopy.scale).to.equal(1.75);
      expect(modelCopy.scaleRange == lt::Interval<CGFloat>::oc({1.25, 1.75})).to.beTruthy();
      expect(modelCopy.spacing).to.equal(0.015625);
    });
  });

  context(@"random initial seed indication", ^{
    it(@"should return a copy with given random initial seed indication", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithRandomInitialSeed:!model.randomInitialSeed];
      expect(modelCopy.randomInitialSeed).to.equal(!model.randomInitialSeed);
      expect(modelCopy.spacing).to.equal(0.015625);
    });
  });

  context(@"initial seed", ^{
    it(@"should return a copy with initial seed", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithInitialSeed:7];
      expect(modelCopy.initialSeed).to.equal(7);
      expect(modelCopy.spacing).to.equal(0.015625);
    });
  });

  context(@"spacing", ^{
    it(@"should return a copy with spacing", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithSpacing:7];
      expect(modelCopy.spacing).toNot.equal(model.spacing);
      expect(modelCopy.spacing).to.equal(7);
    });

    it(@"should return a copy with spacing, clamped to the allowed range", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithSpacing:-1];
      expect(modelCopy.spacing).toNot.equal(model.spacing);
      expect(modelCopy.spacing).to.equal(0.001);
    });
  });

  context(@"number of samples per sequence", ^{
    it(@"should return a copy with number of samples per sequence", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithNumberOfSamplesPerSequence:7];
      expect(modelCopy.numberOfSamplesPerSequence).toNot.equal(model.numberOfSamplesPerSequence);
      expect(modelCopy.numberOfSamplesPerSequence).to.equal(7);
    });
  });

  context(@"sequence distance", ^{
    it(@"should return a copy with sequence distance", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithSequenceDistance:7];
      expect(modelCopy.sequenceDistance).toNot.equal(model.sequenceDistance);
      expect(modelCopy.sequenceDistance).to.equal(7);
    });

    it(@"should return a copy with sequence distance, clamped to the allowed range", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithSequenceDistance:-1];
      expect(modelCopy.sequenceDistance).toNot.equal(model.sequenceDistance);
      expect(modelCopy.sequenceDistance).to.equal(0.001);
    });
  });

  context(@"count range", ^{
    it(@"should return a copy with count range", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithCountRange:lt::Interval<NSUInteger>({1, 7})];
      expect(modelCopy.countRange != model.countRange).to.beTruthy();
      expect(modelCopy.countRange == lt::Interval<NSUInteger>({1, 7})).to.beTruthy();
    });
  });

  context(@"brush tip rotation", ^{
    it(@"should return a copy with rotatedWithSplineDirection", ^{
      DVNBrushModelV1 *modelCopy =
          [model copyWithRotatedWithSplineDirection:!model.rotatedWithSplineDirection];
      expect(modelCopy.rotatedWithSplineDirection).to.equal(!model.rotatedWithSplineDirection);
    });
  });

  context(@"distance jitter factor range", ^{
    it(@"should return a copy with distance jitter factor range", ^{
      DVNBrushModelV1 *modelCopy =
          [model copyWithDistanceJitterFactorRange:lt::Interval<CGFloat>({1, 7})];
      expect(modelCopy.distanceJitterFactorRange != model.distanceJitterFactorRange)
          .to.beTruthy();
      expect(modelCopy.distanceJitterFactorRange == lt::Interval<CGFloat>({1, 7})).to.beTruthy();
    });

    it(@"should return a copy with distance jitter factor range, clamped to the allowed range", ^{
      DVNBrushModelV1 *modelCopy =
          [model copyWithDistanceJitterFactorRange:lt::Interval<CGFloat>({-1, 7})];
      expect(modelCopy.distanceJitterFactorRange != model.distanceJitterFactorRange).to.beTruthy();
      expect(modelCopy.distanceJitterFactorRange == lt::Interval<CGFloat>({0, 7})).to.beTruthy();
    });
  });

  context(@"angle range", ^{
    it(@"should return a copy with angle range", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithAngleRange:lt::Interval<CGFloat>({1, 2})];
      expect(modelCopy.angleRange != model.angleRange).to.beTruthy();
      expect(modelCopy.angleRange == lt::Interval<CGFloat>({1, 2})).to.beTruthy();
    });

    it(@"should return a copy with distance jitter factor range, clamped to the allowed range", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithAngleRange:lt::Interval<CGFloat>({-1, 20})];
      expect(modelCopy.angleRange != model.angleRange).to.beTruthy();
      expect(modelCopy.angleRange == lt::Interval<CGFloat>({0, 4 * M_PI})).to.beTruthy();
    });
  });

  context(@"scale jitter factor range", ^{
    it(@"should return a copy with scale jitter factor range", ^{
      DVNBrushModelV1 *modelCopy =
      [model copyWithScaleJitterRange:lt::Interval<CGFloat>({1, 7})];
      expect(modelCopy.scaleJitterRange != model.scaleJitterRange).to.beTruthy();
      expect(modelCopy.scaleJitterRange == lt::Interval<CGFloat>({1, 7})).to.beTruthy();
    });

    it(@"should return a copy with scale jitter factor range, clamped to the allowed range", ^{
      DVNBrushModelV1 *modelCopy =
      [model copyWithScaleJitterRange:lt::Interval<CGFloat>({-1, 7})];
      expect(modelCopy.scaleJitterRange != model.scaleJitterRange).to.beTruthy();
      expect(modelCopy.scaleJitterRange == lt::Interval<CGFloat>({0, 7})).to.beTruthy();
    });
  });

  context(@"tapering lengths", ^{
    it(@"should return a copy with tapering lengths", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithTaperingLengths:LTVector2(0.5, 0.75)];
      expect(modelCopy.taperingLengths).toNot.equal(model.taperingLengths);
      expect(modelCopy.taperingLengths).to.equal(LTVector2(0.5, 0.75));
    });

    it(@"should return a copy with tapering lengths, clamped to the allowed range", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithTaperingLengths:LTVector2(-0.5, 1.5)];
      expect(modelCopy.taperingLengths).toNot.equal(model.taperingLengths);
      expect(modelCopy.taperingLengths).to.equal(LTVector2(0, 1.5));
    });
  });

  context(@"minimum tapering scale factor", ^{
    it(@"should return a copy with minimum tapering scale factor", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithMinimumTaperingScaleFactor:0.5];
      expect(modelCopy.minimumTaperingScaleFactor).toNot.equal(model.minimumTaperingScaleFactor);
      expect(modelCopy.minimumTaperingScaleFactor).to.equal(0.5);
    });

    it(@"should return a copy with minimum tapering scale factor, clamped to the allowed range", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithMinimumTaperingScaleFactor:7];
      expect(modelCopy.minimumTaperingScaleFactor).toNot.equal(model.minimumTaperingScaleFactor);
      expect(modelCopy.minimumTaperingScaleFactor).to.equal(1);
    });
  });

  context(@"tapering factors", ^{
    it(@"should return a copy with tapering factors", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithTaperingFactors:LTVector2(0.5, 0.75)];
      expect(modelCopy.taperingFactors).toNot.equal(model.taperingFactors);
      expect(modelCopy.taperingFactors).to.equal(LTVector2(0.5, 0.75));
    });

    it(@"should return a copy with tapering factors, clamped to the allowed range", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithTaperingFactors:LTVector2(-0.5, 0.75)];
      expect(modelCopy.taperingFactors).toNot.equal(model.taperingFactors);
      expect(modelCopy.taperingFactors).to.equal(LTVector2(0, 0.75));
    });
  });

  context(@"speed-based tapering factor", ^{
    it(@"should return a copy with speed-based tapering factor", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithSpeedBasedTaperingFactor:0.5];
      expect(modelCopy.speedBasedTaperingFactor).toNot.equal(model.speedBasedTaperingFactor);
      expect(modelCopy.speedBasedTaperingFactor).to.equal(0.5);
    });

    it(@"should return a copy with tapering factors, clamped to the allowed range", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithSpeedBasedTaperingFactor:-1.5];
      expect(modelCopy.speedBasedTaperingFactor).toNot.equal(model.speedBasedTaperingFactor);
      expect(modelCopy.speedBasedTaperingFactor).to.equal(-1);
    });
  });

  context(@"flow", ^{
    it(@"should return a copy with flow", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithFlow:0.07];
      expect(modelCopy.flow).to.equal(0.07);
      expect(modelCopy.spacing).to.equal(0.015625);
    });

    it(@"should return a copy with flow, clamped to the flow range", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithFlow:0];
      expect(modelCopy.flow).to.equal(0.0625);
      expect(modelCopy.spacing).to.equal(0.015625);
    });
  });

  context(@"flow exponent", ^{
    it(@"should return a copy with flow exponent", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithFlowExponent:7];
      expect(modelCopy.flowExponent).toNot.equal(model.flowExponent);
      expect(modelCopy.flowExponent).to.equal(7);
    });

    it(@"should return a copy with flow exponent, clamped to the allowed range", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithFlowExponent:-7];
      expect(modelCopy.flowExponent).toNot.equal(model.flowExponent);
      expect(modelCopy.flowExponent).to.equal(std::nextafter((CGFloat)0, (CGFloat)1));
    });
  });

  context(@"color", ^{
    it(@"should return a copy with given color", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithColor:LTVector3(0.25, 0.5, 0.75)];
      expect(modelCopy.color).to.equal(LTVector3(0.25, 0.5, 0.75));
      expect(modelCopy.spacing).to.equal(0.015625);
    });

    it(@"should return a copy with given edge avoidance, clamped to the allowed range", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithColor:LTVector3(0.25, 0.5, 1.75)];
      expect(modelCopy.color).to.equal(LTVector3(0.25, 0.5, 1));
      expect(modelCopy.spacing).to.equal(0.015625);
    });
  });

  context(@"brightness jitter", ^{
    it(@"should return a copy with brightness jitter", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithBrightnessJitter:0.5];
      expect(modelCopy.brightnessJitter).toNot.equal(model.brightnessJitter);
      expect(modelCopy.brightnessJitter).to.equal(0.5);
    });

    it(@"should return a copy with brightness jitter, clamped to the allowed range", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithBrightnessJitter:1.5];
      expect(modelCopy.brightnessJitter).toNot.equal(model.brightnessJitter);
      expect(modelCopy.brightnessJitter).to.equal(1);
    });
  });

  context(@"hue jitter", ^{
    it(@"should return a copy with hue jitter", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithHueJitter:0.5];
      expect(modelCopy.hueJitter).toNot.equal(model.hueJitter);
      expect(modelCopy.hueJitter).to.equal(0.5);
    });

    it(@"should return a copy with hue jitter, clamped to the allowed range", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithHueJitter:1.5];
      expect(modelCopy.hueJitter).toNot.equal(model.hueJitter);
      expect(modelCopy.hueJitter).to.equal(1);
    });
  });

  context(@"saturation jitter", ^{
    it(@"should return a copy with saturation jitter", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithSaturationJitter:0.5];
      expect(modelCopy.saturationJitter).toNot.equal(model.saturationJitter);
      expect(modelCopy.saturationJitter).to.equal(0.5);
    });

    it(@"should return a copy with saturation jitter, clamped to the allowed range", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithSaturationJitter:1.5];
      expect(modelCopy.saturationJitter).toNot.equal(model.saturationJitter);
      expect(modelCopy.saturationJitter).to.equal(1);
    });
  });

  context(@"source sampling mode", ^{
    it(@"should return a copy with given source sampling mode", ^{
      DVNBrushModelV1 *modelCopy =
          [model copyWithSourceSamplingMode:$(DVNSourceSamplingModeFixed)];
      expect(modelCopy.sourceSamplingMode).toNot.equal(model.sourceSamplingMode);
      expect(modelCopy.sourceSamplingMode).to.equal($(DVNSourceSamplingModeFixed));
    });
  });

  context(@"grid size", ^{
    it(@"should return a copy with grid size", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithBrushTipImageGridSize:LTVector2(8, 9)];
      expect(modelCopy.brushTipImageGridSize).toNot.equal(model.brushTipImageGridSize);
      expect(modelCopy.brushTipImageGridSize).to.equal(LTVector2(8, 9));
    });

    it(@"should return a copy with grid size, clamped to the allowed range", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithBrushTipImageGridSize:LTVector2(-7, 8.7)];
      expect(modelCopy.brushTipImageGridSize).toNot.equal(model.brushTipImageGridSize);
      expect(modelCopy.brushTipImageGridSize).to.equal(LTVector2(1, 9));
    });
  });

  context(@"source image URL", ^{
    it(@"should return a copy with given source image URL", ^{
      NSURL *url = [NSURL URLWithString:@"foo"];
      DVNBrushModelV1 *modelCopy = [model copyWithSourceImageURL:url];
      expect(modelCopy.sourceImageURL).toNot.equal(model.sourceImageURL);
      expect(modelCopy.sourceImageURL).to.equal(url);
    });
  });

  context(@"source image is non premultiplied indication", ^{
    it(@"should return a copy with given source image is non premultiplied indication", ^{
      DVNBrushModelV1 *modelCopy =
          [model copyWithSourceImageIsNonPremultiplied:!model.sourceImageIsNonPremultiplied];
      expect(modelCopy.sourceImageIsNonPremultiplied)
          .to.equal(!model.sourceImageIsNonPremultiplied);
    });
  });

  context(@"mask image URL", ^{
    it(@"should return a copy with given mask image URL", ^{
      NSURL *url = [NSURL URLWithString:@"foo"];
      DVNBrushModelV1 *modelCopy = [model copyWithMaskImageURL:url];
      expect(modelCopy.maskImageURL).toNot.equal(model.maskImageURL);
      expect(modelCopy.maskImageURL).to.equal(url);
    });
  });

  context(@"blend mode", ^{
    it(@"should return a copy with given blend mode", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithBlendMode:$(DVNBlendModeDarken)];
      expect(modelCopy.blendMode).to.equal($(DVNBlendModeDarken));
      expect(modelCopy.spacing).to.equal(0.015625);
    });
  });

  context(@"edge avoidance", ^{
    it(@"should return a copy with given edge avoidance", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithEdgeAvoidance:0.5];
      expect(modelCopy.edgeAvoidance).to.equal(0.5);
      expect(modelCopy.spacing).to.equal(0.015625);
    });

    it(@"should return a copy with given edge avoidance, clamped to the allowed range", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithEdgeAvoidance:-1];
      expect(modelCopy.edgeAvoidance).to.equal(0);
      expect(modelCopy.spacing).to.equal(0.015625);
    });
  });

  context(@"edge avoidance guide image URL", ^{
    it(@"should return a copy with given edge avoidance guide image URL", ^{
      NSURL *url = [NSURL URLWithString:@"foo"];
      DVNBrushModelV1 *modelCopy = [model copyWithEdgeAvoidanceGuideImageURL:url];
      expect(modelCopy.edgeAvoidanceGuideImageURL).toNot.equal(model.edgeAvoidanceGuideImageURL);
      expect(modelCopy.edgeAvoidanceGuideImageURL).to.equal(url);
    });
  });

  context(@"edge avoidance sampling offset", ^{
    it(@"should return a copy with edge avoidance sampling offset", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithEdgeAvoidanceSamplingOffset:7];
      expect(modelCopy.edgeAvoidanceSamplingOffset).toNot.equal(model.edgeAvoidanceSamplingOffset);
      expect(modelCopy.edgeAvoidanceSamplingOffset).to.equal(7);
    });

    it(@"should return a copy with flow exponent, clamped to the allowed range", ^{
      DVNBrushModelV1 *modelCopy = [model copyWithEdgeAvoidanceSamplingOffset:-7];
      expect(modelCopy.edgeAvoidanceSamplingOffset).toNot.equal(model.edgeAvoidanceSamplingOffset);
      expect(modelCopy.edgeAvoidanceSamplingOffset).to.equal(0);
    });
  });
});

context(@"texture mapping validation", ^{
  __block DVNBrushModelV1 *model;

  beforeEach(^{
    NSDictionary *jsonDictionary = DVNJSONDictionaryOfTestBrushModelV1();
    model = [MTLJSONAdapter modelOfClass:[DVNBrushModelV1 class] fromJSONDictionary:jsonDictionary
                                   error:nil];
  });

  it(@"should claim that given texture mapping is valid", ^{
    auto textureMapping = @{
      @keypath(model, sourceImageURL): OCMClassMock([LTTexture class]),
      @keypath(model, maskImageURL): OCMClassMock([LTTexture class]),
      @keypath(model, edgeAvoidanceGuideImageURL): OCMClassMock([LTTexture class])
    };

    expect([model isValidTextureMapping:textureMapping]).to.beTruthy();
  });

  it(@"should claim that texture mapping is invalid if keys are not subset of property keys", ^{
    auto textureMapping = @{
      @keypath(model, sourceImageURL): OCMClassMock([LTTexture class]),
      @keypath(model, maskImageURL): OCMClassMock([LTTexture class]),
      @keypath(model, edgeAvoidanceGuideImageURL): OCMClassMock([LTTexture class]),
      @"foo": OCMClassMock([LTTexture class])
    };

    expect([model isValidTextureMapping:textureMapping]).to.beFalsy();
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
  static const CGFloat kFloatMax = std::numeric_limits<float>::max();
  static const CGFloat kCGFloatMax = std::numeric_limits<CGFloat>::max();
  static const NSUInteger kNSUIntegerMax = std::numeric_limits<NSUInteger>::max();

  it(@"should return the allowed scale range", ^{
    expect([DVNBrushModel allowedScaleRange] == lt::Interval<CGFloat>::oc({0, kCGFloatMax}))
        .to.beTruthy();
    expect([DVNBrushModelV1 allowedInitialSeedRange] ==
           lt::Interval<NSUInteger>::nonNegativeNumbers()).to.beTruthy();
    expect([DVNBrushModel allowedSplineSmoothnessRange] == lt::Interval<CGFloat>::zeroToOne())
        .to.beTruthy();
    expect([DVNBrushModelV1 allowedSpacingRange] ==
           lt::Interval<CGFloat>({0.001, kCGFloatMax})).to.beTruthy();
    expect([DVNBrushModelV1 allowedNumberOfSamplesPerSequenceRange] ==
           lt::Interval<NSUInteger>({1, kNSUIntegerMax})).to.beTruthy();
    expect([DVNBrushModelV1 allowedSequenceDistanceRange] ==
           lt::Interval<CGFloat>({0.001, kCGFloatMax})).to.beTruthy();
    expect([DVNBrushModelV1 allowedCountRange] ==
           lt::Interval<NSUInteger>::nonNegativeNumbers()).to.beTruthy();
    expect([DVNBrushModelV1 allowedDistanceJitterFactorRange] ==
           lt::Interval<CGFloat>::nonNegativeNumbers()).to.beTruthy();
    expect([DVNBrushModelV1 allowedAngleRange] == lt::Interval<CGFloat>({0, 4 * M_PI}))
        .to.beTruthy();
    expect([DVNBrushModelV1 allowedScaleJitterRange] == lt::Interval<CGFloat>({0, kCGFloatMax}))
        .to.beTruthy();
    expect([DVNBrushModelV1 allowedTaperingLengthRange] == lt::Interval<float>({0, kFloatMax}))
        .to.beTruthy();
    expect([DVNBrushModelV1 allowedMinimumTaperingScaleFactorRange] ==
           lt::Interval<CGFloat>::oc({0, 1})).to.beTruthy();
    expect([DVNBrushModelV1 allowedTaperingFactorRange] == lt::Interval<float>({0, 1}))
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
           lt::Interval<CGFloat>::nonNegativeNumbers()).to.beTruthy();
  });
});

SpecEnd
