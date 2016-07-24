// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNAttributeProviderExamples.h"

#import <LTEngine/LTAttributeData.h>
#import <LTEngineTests/LTEasyVectorBoxing.h>

#import "DVNAttributeProvider.h"
#import "DVNEasyQuadVectorBoxing.h"

NSString * const kDVNAttributeProviderExamples = @"DVNAttributeProviderExamples";
NSString * const kDVNAttributeProviderExamplesModel = @"DVNAttributeProviderExamplesModel";
NSString * const kDVNAttributeProviderExamplesInputQuads =
    @"DVNAttributeProviderExamplesInputQuads";
NSString * const kDVNAttributeProviderExamplesInputIndices =
    @"DVNAttributeProviderExamplesInputIndices";
NSString * const kDVNAttributeProviderExamplesInputSample =
    @"DVNAttributeProviderExamplesInputSample";
NSString * const kDVNAttributeProviderExamplesExpectedData =
    @"DVNAttributeProviderExamplesExpectedData";
NSString * const kDVNAttributeProviderExamplesExpectedGPUStruct =
    @"DVNAttributeProviderExamplesExpectedGPUStruct";

SharedExamplesBegin(DVNAttributeProviderExamples)

sharedExamplesFor(kDVNAttributeProviderExamples, ^(NSDictionary *data) {
  __block id<DVNAttributeProviderModel> model;
  __block dvn::GeometryValues geometryValues;
  __block NSData *expectedData;
  __block LTGPUStruct *expectedGPUStruct;

  beforeEach(^{
    model = data[kDVNAttributeProviderExamplesModel];
    NSArray<NSNumber *> *boxedIndices = data[kDVNAttributeProviderExamplesInputIndices];
    std::vector<NSUInteger> indices;
    for (NSNumber *index in boxedIndices) {
      indices.push_back([index unsignedIntegerValue]);
    }

    std::vector<lt::Quad> quads =
        DVNConvertedQuadsFromQuads(data[kDVNAttributeProviderExamplesInputQuads]);

    geometryValues =
        dvn::GeometryValues(quads, indices, data[kDVNAttributeProviderExamplesInputSample]);
    expectedData = data[kDVNAttributeProviderExamplesExpectedData];
    expectedGPUStruct = data[kDVNAttributeProviderExamplesExpectedGPUStruct];
  });

  afterEach(^{
    model = nil;
  });

  context(@"model", ^{
    it(@"should return a provider", ^{
      expect([model provider]).toNot.beNil();
    });

    it(@"should return a provider with the same model", ^{
      expect([[model provider] currentModel]).to.equal(model);
    });

    it(@"should return a correct sample attribute data", ^{
      LTAttributeData *attributeData = [model sampleAttributeData];
      expect(attributeData).toNot.beNil();
      expect(attributeData.data.length).to.equal(0);
      expect(attributeData.gpuStruct).to.equal(expectedGPUStruct);
    });
  });

  context(@"provider", ^{
    __block id<DVNAttributeProvider> provider;

    beforeEach(^{
      provider = [model provider];
    });

    afterEach(^{
      provider = nil;
    });

    context(@"providing texture map quads", ^{
      it(@"should provide the expected quads", ^{
        LTAttributeData *attributeData = [provider attributeDataFromGeometryValues:geometryValues];
        LTAttributeData *expectedAttributeData =
            [[LTAttributeData alloc] initWithData:expectedData
                              inFormatOfGPUStruct:expectedGPUStruct];
        expect(attributeData).to.equal(expectedAttributeData);
      });

      it(@"should reproduce the same attribute data when using the same model", ^{
        LTAttributeData *attributeData = [provider attributeDataFromGeometryValues:geometryValues];
        id<DVNAttributeProvider> otherProvider = [model provider];
        LTAttributeData *otherAttributeData =
            [otherProvider attributeDataFromGeometryValues:geometryValues];
        expect(otherAttributeData).to.equal(attributeData);
      });
    });

    context(@"model", ^{
      it(@"should reproduce the same model", ^{
        [provider attributeDataFromGeometryValues:geometryValues];
        id<DVNAttributeProviderModel> currentModel = [provider currentModel];
        id<DVNAttributeProvider> otherProvider = [model provider];
        [otherProvider attributeDataFromGeometryValues:geometryValues];
        expect([otherProvider currentModel]).to.equal(currentModel);
      });
    });
  });
});

SharedExamplesEnd
