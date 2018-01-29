// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushModelV1.h"

#import <LTKit/NSArray+NSSet.h>

#import "DVNBlendMode.h"
#import "DVNBrushModelVersion.h"

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
    NSString *filePath = [[NSBundle bundleForClass:[self class]]
                          pathForResource:@"DVNTestBrushModelV1" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0
                                                       error:nil];
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
      expect(model.minScale).to.equal(1.00390625);
      expect(model.scale).to.equal(1.0078125);
      expect(model.maxScale).to.equal(1.0117188);

      // DVNBrushModelV1
      expect(model.randomInitialSeed).to.beTruthy();
      expect(model.initialSeed).to.equal(7);
      expect(model.spacing).to.equal(0.015625);
      expect(model.numberOfSamplesPerSequence).to.equal(8);
      expect(model.sequenceDistance).to.equal(0.0195312);
      expect(model.minCount).to.equal(9);
      expect(model.maxCount).to.equal(10);
      expect(model.minDistanceJitterFactor).to.equal(0.0234375);
      expect(model.maxDistanceJitterFactor).to.equal(0.0273438);
      expect(model.minAngle).to.equal(0.03125);
      expect(model.maxAngle).to.equal(0.0351562);
      expect(model.minScaleJitter).to.equal(0.0390625);
      expect(model.maxScaleJitter).to.equal(0.0429688);
      expect(model.lengthOfStartTapering).to.equal(0.046875);
      expect(model.lengthOfEndTapering).to.equal(0.0507812);
      expect(model.minimumTaperingScaleFactor).to.equal(0.0546875);
      expect(model.taperingExponent).to.equal(0.0585938);
      expect(model.minFlow).to.equal(0.0625);
      expect(model.flow).to.equal(0.0664062);
      expect(model.maxFlow).to.equal(0.0703125);
      expect(model.flowExponent).to.equal(0.0742188);
      expect(model.color).to.equal(LTVector3(0.88, 0, 0));
      expect(model.brightnessJitter).to.equal(0.078125);
      expect(model.hueJitter).to.equal(0.0820312);
      expect(model.saturationJitter).to.equal(0.0859375);
      expect(model.brushTipImageURL).to.equal([NSURL URLWithString:@"image://brushTip"]);
      expect(model.brushTipImageGridSize).to.equal(LTVector2(7, 8));
      expect(model.overlayImageURL).to.equal([NSURL URLWithString:@"image://overlay"]);
      expect(model.blendMode).to.equal($(DVNBlendModeDarken));
      expect(model.edgeAvoidance).to.equal(0.0898438);
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
    NSSet *expectedKeys = @[@instanceKeypath(DVNBrushModelV1, brushTipImageURL),
                            @instanceKeypath(DVNBrushModelV1, overlayImageURL)].lt_set;
    expect([DVNBrushModelV1 imageURLPropertyKeys].lt_set).to.equal(expectedKeys);
  });
});

SpecEnd
