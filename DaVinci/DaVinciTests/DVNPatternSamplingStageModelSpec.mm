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
  beforeEach(^{
    model.spacing = 1;
    model.numberOfSamplesPerSequence = 2;
    model.sequenceDistance = 3;
  });
  
  it(@"should return LTFloatSetSamplerModel sampler model", ^{
    id<LTContinuousSamplerModel> samplerModel = [model continuousSamplerModel];
    expect(samplerModel).to.beKindOf([LTFloatSetSamplerModel class]);
  });
  
  it(@"should return sampler with periodic float set", ^{
    LTFloatSetSamplerModel *samplerModel = [model continuousSamplerModel];
    expect(samplerModel.floatSet).to.beKindOf([LTPeriodicFloatSet class]);
  });
  
  it(@"should return sampler with correct periodic float set", ^{
    LTFloatSetSamplerModel *samplerModel = [model continuousSamplerModel];
    LTPeriodicFloatSet *floatSet = samplerModel.floatSet;
    expect(floatSet.pivotValue).to.equal(0);
    expect(floatSet.numberOfValuesPerSequence).to.equal(2);
    expect(floatSet.valueDistance).to.equal(1);
    expect(floatSet.sequenceDistance).to.equal(3);
  });
  
  it(@"should return sampler with correct interval", ^{
    LTFloatSetSamplerModel *samplerModel = [model continuousSamplerModel];
    lt::Interval<CGFloat> interval = samplerModel.interval;
    expect(interval.min()).to.equal(0);
    expect(interval.max()).to.equal(CGFLOAT_MAX);
    expect(interval.maxEndpointIncluded())
        .to.equal(lt::Interval<CGFloat>::EndpointInclusion::Closed);
  });
});

context(@"de/serialization", ^{
  __block NSDictionary *dictionary;
  __block NSError *error;
  
  beforeEach(^{
    dictionary = @{
      @instanceKeypath(DVNPatternSamplingStageModel, spacing): @1,
      @instanceKeypath(DVNPatternSamplingStageModel, defaultSpacing): @2,
      @instanceKeypath(DVNPatternSamplingStageModel, minSpacing): @3,
      @instanceKeypath(DVNPatternSamplingStageModel, maxSpacing): @4,
      @instanceKeypath(DVNPatternSamplingStageModel, numberOfSamplesPerSequence): @5,
      @instanceKeypath(DVNPatternSamplingStageModel, defaultNumberOfSamplesPerSequence): @6,
      @instanceKeypath(DVNPatternSamplingStageModel, minNumberOfSamplesPerSequence): @7,
      @instanceKeypath(DVNPatternSamplingStageModel, maxNumberOfSamplesPerSequence): @8,
      @instanceKeypath(DVNPatternSamplingStageModel, sequenceDistance): @9,
      @instanceKeypath(DVNPatternSamplingStageModel, defaultSequenceDistance): @10,
      @instanceKeypath(DVNPatternSamplingStageModel, minSequenceDistance): @11,
      @instanceKeypath(DVNPatternSamplingStageModel, maxSequenceDistance): @12
    };
    model = [MTLJSONAdapter modelOfClass:[DVNPatternSamplingStageModel class]
                      fromJSONDictionary:dictionary error:&error];
  });
  
  context(@"deserialization", ^{
    it(@"should deserialize without errors", ^{
      expect(error).to.beNil();
    });
    
    it(@"should deserialize correctly", ^{
      expect(model.spacing).to.equal(1);
      expect(model.defaultSpacing).to.equal(2);
      expect(model.minSpacing).to.equal(3);
      expect(model.maxSpacing).to.equal(4);
      expect(model.numberOfSamplesPerSequence).to.equal(5);
      expect(model.defaultNumberOfSamplesPerSequence).to.equal(6);
      expect(model.minNumberOfSamplesPerSequence).to.equal(7);
      expect(model.maxNumberOfSamplesPerSequence).to.equal(8);
      expect(model.sequenceDistance).to.equal(9);
      expect(model.defaultSequenceDistance).to.equal(10);
      expect(model.minSequenceDistance).to.equal(11);
      expect(model.maxSequenceDistance).to.equal(12);
    });
  });
  
  context(@"serialization", ^{
    it(@"should serialize correctly", ^{
      expect([MTLJSONAdapter JSONDictionaryFromModel:model]).to.equal(dictionary);
    });
  });
});

SpecEnd
