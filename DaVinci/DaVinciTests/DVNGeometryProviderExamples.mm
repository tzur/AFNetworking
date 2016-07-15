// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNGeometryProviderExamples.h"

#import <LTEngine/LTSampleValues.h>
#import <LTEngineTests/LTEasyVectorBoxing.h>

#import "DVNEasyQuadVectorBoxing.h"
#import "DVNGeometryProvider.h"

NSString * const kDVNGeometryProviderExamples = @"DVNGeometryProviderExamples";
NSString * const kDVNGeometryProviderExamplesModel = @"DVNGeometryProviderExamplesModel";
NSString * const kDVNGeometryProviderExamplesSamples = @"DVNGeometryProviderExamplesSamples";
NSString * const kDVNGeometryProviderExamplesExpectedQuads =
    @"DVNGeometryProviderExamplesExpectedQuads";
NSString * const kDVNGeometryProviderExamplesExpectedIndices =
    @"DVNGeometryProviderExamplesExpectedIndices";

SharedExamplesBegin(DVNGeometryProviderExamples)

sharedExamplesFor(kDVNGeometryProviderExamples, ^(NSDictionary *data) {
  __block id<DVNGeometryProviderModel> model;
  __block id<LTSampleValues> samples;
  __block NSArray<LTQuad *> *expectedQuads;
  __block NSArray<NSNumber *> *expectedIndices;

  beforeEach(^{
    model = data[kDVNGeometryProviderExamplesModel];
    samples = data[kDVNGeometryProviderExamplesSamples];
    expectedQuads = data[kDVNGeometryProviderExamplesExpectedQuads];
    expectedIndices = data[kDVNGeometryProviderExamplesExpectedIndices];
  });

  afterEach(^{
    expectedIndices = nil;
    expectedQuads = nil;
    samples = nil;
    model = nil;
  });

  context(@"model", ^{
    it(@"should return a provider", ^{
      expect([model provider]).toNot.beNil();
    });

    it(@"should return a provider with the same model", ^{
      expect([[model provider] currentModel]).to.equal(model);
    });
  });

  context(@"provider", ^{
    __block id<DVNGeometryProvider> provider;

    beforeEach(^{
      provider = [model provider];
    });

    afterEach(^{
      provider = nil;
    });

    context(@"providing geometry", ^{
      it(@"should provide the expected quads", ^{
        dvn::GeometryValues values = [provider valuesFromSamples:samples end:NO];
        expect(DVNConvertedQuadsFromQuads(values.quads())).to.equal(expectedQuads);
        expect($(values.indices())).to.equal(expectedIndices);
        expect(values.samples()).to.equal(samples);
      });

      it(@"should reproduce the same values when using the same model", ^{
        dvn::GeometryValues values = [provider valuesFromSamples:samples end:NO];
        id<DVNGeometryProvider> otherProvider = [model provider];
        dvn::GeometryValues otherValues = [otherProvider valuesFromSamples:samples end:NO];
        expect(values == otherValues).to.beTruthy();
      });
    });

    context(@"model", ^{
      it(@"should reproduce the same model", ^{
        [provider valuesFromSamples:samples end:NO];
        id<DVNGeometryProviderModel> currentModel = [provider currentModel];
        id<DVNGeometryProvider> otherProvider = [model provider];
        [otherProvider valuesFromSamples:samples end:NO];
        expect([otherProvider currentModel]).to.equal(currentModel);
      });
    });
  });
});

SharedExamplesEnd
