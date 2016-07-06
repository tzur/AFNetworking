// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSampleValues.h"

#import "LTEasyVectorBoxing.h"
#import "LTParameterizationKeyToValues.h"

SpecBegin(LTSampleValues)

static const CGFloats kValues = {1, 2, 3};

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

SpecEnd
