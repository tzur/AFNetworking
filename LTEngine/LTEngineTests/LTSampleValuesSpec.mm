// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSampleValues.h"

#import "LTEasyVectorBoxing.h"
#import "LTParameterizationKeyToValues.h"

SpecBegin(LTSampleValues)

static const std::vector<CGFloat> kValues = {1, 2, 3};

__block NSOrderedSet *keys;

beforeEach(^{
  keys = [NSOrderedSet orderedSetWithObject:@"key"];
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    cv::Mat1g matrix(1, 3);
    LTParameterizationKeyToValues *mapping =
        [[LTParameterizationKeyToValues alloc] initWithKeys:keys valuesPerKey:matrix];
    LTSampleValues *sampleValues = [[LTSampleValues alloc] initWithSampledParametricValues:kValues
                                                                                   mapping:mapping];
    expect(sampleValues).toNot.beNil();
    expect($(sampleValues.sampledParametricValues)).to.equal($(kValues));
    expect(sampleValues.mappingOfSampledValues).to.equal(mapping);
  });

  it(@"should initialize correctly with zero values", ^{
    LTSampleValues *sampleValues = [[LTSampleValues alloc] initWithSampledParametricValues:{}
                                                                                   mapping:nil];
    expect(sampleValues).toNot.beNil();
    expect(sampleValues.mappingOfSampledValues).to.beNil();
  });

  it(@"should raise when attempting to initialize with mismatching number of values", ^{
    cv::Mat1g matrix(1, 2);
    LTParameterizationKeyToValues *mapping =
        [[LTParameterizationKeyToValues alloc] initWithKeys:keys valuesPerKey:matrix];
    expect(^{
        LTSampleValues __unused *sampleValues =
                   [[LTSampleValues alloc] initWithSampledParametricValues:kValues mapping:mapping];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"concatenation", ^{
  static NSOrderedSet<NSString *> * const kKeys =
      [NSOrderedSet orderedSetWithArray:@[@"foo", @"bar"]];

  __block cv::Mat1g matrix;

  beforeEach(^{
    matrix = (cv::Mat1g(2, 1) << 0, 3);
  });

  it(@"should return concatenation of copy of receiver with given object", ^{
    LTParameterizationKeyToValues *mapping =
        [[LTParameterizationKeyToValues alloc] initWithKeys:kKeys valuesPerKey:matrix];
    LTSampleValues *sampleValues = [[LTSampleValues alloc] initWithSampledParametricValues:{1}
                                                                                   mapping:mapping];
    cv::Mat1g otherMatrix = (cv::Mat1g(2, 2) << 1, 2, 4, 5);
    mapping = [[LTParameterizationKeyToValues alloc] initWithKeys:kKeys valuesPerKey:otherMatrix];
    LTSampleValues *otherSampleValues =
        [[LTSampleValues alloc] initWithSampledParametricValues:{2, 3} mapping:mapping];

    LTSampleValues *result = [sampleValues concatenatedWithSampleValues:otherSampleValues];

    std::vector<CGFloat> expectedSampledParametricValues = {1, 2, 3};
    cv::Mat1g expectedMatrix = (cv::Mat1g(2, 3) << 0, 1, 2, 3, 4, 5);
    expect($(result.sampledParametricValues)).to.equal($(expectedSampledParametricValues));
    expect(result.mappingOfSampledValues.keys).to.equal(kKeys);
    expect(result.mappingOfSampledValues.numberOfValuesPerKey).to.equal(3);
    expect($(result.mappingOfSampledValues.valuesPerKey)).to.equalMat($(expectedMatrix));
  });

  context(@"empty sample values", ^{
    it(@"should return concatenation of copy of empty receiver with given object", ^{
      LTSampleValues *sampleValues = [[LTSampleValues alloc] initWithSampledParametricValues:{}
                                                                                     mapping:nil];
      LTParameterizationKeyToValues *mapping = [[LTParameterizationKeyToValues alloc]
                                                initWithKeys:kKeys valuesPerKey:matrix];
      LTSampleValues *otherSampleValues =
          [[LTSampleValues alloc] initWithSampledParametricValues:{1} mapping:mapping];

      LTSampleValues *result = [sampleValues concatenatedWithSampleValues:otherSampleValues];

      std::vector<CGFloat> expectedSampledParametricValues = {1};
      expect($(result.sampledParametricValues)).to.equal($(expectedSampledParametricValues));
      expect(result.mappingOfSampledValues.keys).to.equal(kKeys);
      expect(result.mappingOfSampledValues.numberOfValuesPerKey).to.equal(1);
      expect($(result.mappingOfSampledValues.valuesPerKey)).to.equalMat($(matrix));
    });

    it(@"should return concatenation of copy of receiver with given empty object", ^{
      LTParameterizationKeyToValues *mapping = [[LTParameterizationKeyToValues alloc]
                                                initWithKeys:kKeys valuesPerKey:matrix];
      LTSampleValues *sampleValues = [[LTSampleValues alloc]
                                      initWithSampledParametricValues:{1} mapping:mapping];
      LTSampleValues *otherSampleValues = [[LTSampleValues alloc]
                                           initWithSampledParametricValues:{} mapping:nil];

      LTSampleValues *result = [sampleValues concatenatedWithSampleValues:otherSampleValues];

      std::vector<CGFloat> expectedSampledParametricValues = {1};
      expect($(result.sampledParametricValues)).to.equal($(expectedSampledParametricValues));
      expect(result.mappingOfSampledValues.keys).to.equal(kKeys);
      expect(result.mappingOfSampledValues.numberOfValuesPerKey).to.equal(1);
      expect($(result.mappingOfSampledValues.valuesPerKey)).to.equalMat($(matrix));
    });

    it(@"should return concatenation of copy of empty receiver with given empty object", ^{
      LTSampleValues *sampleValues = [[LTSampleValues alloc]
                                      initWithSampledParametricValues:{} mapping:nil];
      LTSampleValues *otherSampleValues = [[LTSampleValues alloc]
                                           initWithSampledParametricValues:{} mapping:nil];

      LTSampleValues *result = [sampleValues concatenatedWithSampleValues:otherSampleValues];

      std::vector<CGFloat> expectedSampledParametricValues = {};
      expect($(result.sampledParametricValues)).to.equal($(expectedSampledParametricValues));
      expect(result.mappingOfSampledValues).to.beNil();
    });
  });
});

SpecEnd
