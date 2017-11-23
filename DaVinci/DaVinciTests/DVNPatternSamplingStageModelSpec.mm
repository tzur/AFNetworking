// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNPatternSamplingStageModel.h"

#import <LTEngine/LTContinuousSampler.h>
#import <LTEngine/LTFloatSetSampler.h>
#import <LTEngine/LTPeriodicFloatSet.h>

SpecBegin(DVNPatternSamplingStageModel)

__block DVNPatternSamplingStageModel *model;

beforeEach(^{
  model = [[DVNPatternSamplingStageModel alloc] init];
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    expect(model).toNot.beNil();
  });
});

context(@"DVNSamplingStageModel", ^{
  it(@"should return LTFloatSetSamplerModel sampler model", ^{
    id<LTContinuousSamplerModel> samplerModel = [model continuousSamplerModel];
    expect(samplerModel).to.beKindOf([LTFloatSetSamplerModel class]);
  });

  it(@"should return sampler with periodic float set", ^{
    LTFloatSetSamplerModel *samplerModel = [model continuousSamplerModel];
    expect(samplerModel.floatSet).to.beKindOf([LTPeriodicFloatSet class]);
  });

  it(@"should return sampler with correct periodic float set using default properties", ^{
    LTFloatSetSamplerModel *samplerModel = [model continuousSamplerModel];
    LTPeriodicFloatSet *floatSet = samplerModel.floatSet;
    expect(floatSet.pivotValue).to.equal(0);
    expect(floatSet.numberOfValuesPerSequence).to.equal(model.numberOfSamplesPerSequence);
    expect(floatSet.valueDistance).to.equal(model.spacing);
    expect(floatSet.sequenceDistance).to.equal(model.sequenceDistance);
  });

  it(@"should return sampler with correct periodic float set using non-default properties", ^{
    model.numberOfSamplesPerSequence = 5;
    model.spacing = 6;
    model.sequenceDistance = 7;

    LTFloatSetSamplerModel *samplerModel = [model continuousSamplerModel];
    LTPeriodicFloatSet *floatSet = samplerModel.floatSet;
    expect(floatSet.pivotValue).to.equal(0);
    expect(floatSet.numberOfValuesPerSequence).to.equal(model.numberOfSamplesPerSequence);
    expect(floatSet.valueDistance).to.equal(model.spacing);
    expect(floatSet.sequenceDistance).to.equal(model.sequenceDistance);
  });

  it(@"should return sampler with correct interval", ^{
    LTFloatSetSamplerModel *samplerModel = [model continuousSamplerModel];
    lt::Interval<CGFloat> interval = samplerModel.interval;
    expect(interval.inf()).to.equal(0);
    expect(interval.sup()).to.equal(CGFLOAT_MAX);
    expect(interval.supIncluded()).to.equal(lt::Interval<CGFloat>::EndpointInclusion::Closed);
  });
});

context(@"de/serialization", ^{
  __block NSDictionary *dictionary;
  __block NSError *error;

  beforeEach(^{
    dictionary = @{
      @instanceKeypath(DVNPatternSamplingStageModel, softMinSpacing): @1,
      @instanceKeypath(DVNPatternSamplingStageModel, spacing): @2,
      @instanceKeypath(DVNPatternSamplingStageModel, defaultSpacing): @3,
      @instanceKeypath(DVNPatternSamplingStageModel, softMaxSpacing): @4,
      @instanceKeypath(DVNPatternSamplingStageModel, softMinNumberOfSamplesPerSequence): @5,
      @instanceKeypath(DVNPatternSamplingStageModel, numberOfSamplesPerSequence): @6,
      @instanceKeypath(DVNPatternSamplingStageModel, defaultNumberOfSamplesPerSequence): @7,
      @instanceKeypath(DVNPatternSamplingStageModel, softMaxNumberOfSamplesPerSequence): @8,
      @instanceKeypath(DVNPatternSamplingStageModel, softMinSequenceDistance): @9,
      @instanceKeypath(DVNPatternSamplingStageModel, sequenceDistance): @10,
      @instanceKeypath(DVNPatternSamplingStageModel, defaultSequenceDistance): @11,
      @instanceKeypath(DVNPatternSamplingStageModel, softMaxSequenceDistance): @12
    };
    model = [MTLJSONAdapter modelOfClass:[DVNPatternSamplingStageModel class]
                      fromJSONDictionary:dictionary error:&error];
  });

  context(@"deserialization", ^{
    it(@"should deserialize without errors", ^{
      expect(error).to.beNil();
    });

    it(@"should deserialize correctly", ^{
      expect(model.softMinSpacing).to.equal(1);
      expect(model.spacing).to.equal(2);
      expect(model.defaultSpacing).to.equal(3);
      expect(model.softMaxSpacing).to.equal(4);
      expect(model.softMinNumberOfSamplesPerSequence).to.equal(5);
      expect(model.numberOfSamplesPerSequence).to.equal(6);
      expect(model.defaultNumberOfSamplesPerSequence).to.equal(7);
      expect(model.softMaxNumberOfSamplesPerSequence).to.equal(8);
      expect(model.softMinSequenceDistance).to.equal(9);
      expect(model.sequenceDistance).to.equal(10);
      expect(model.defaultSequenceDistance).to.equal(11);
      expect(model.softMaxSequenceDistance).to.equal(12);
    });
  });

  context(@"serialization", ^{
    it(@"should serialize correctly", ^{
      expect([MTLJSONAdapter JSONDictionaryFromModel:model]).to.equal(dictionary);
    });
  });
});

SpecEnd
