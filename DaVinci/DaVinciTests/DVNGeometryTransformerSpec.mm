// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNGeometryTransformer.h"

#import <LTEngine/LTParameterizationKeyToValues.h>
#import <LTEngine/LTSampleValues.h>
#import <LTEngineTests/LTEasyVectorBoxing.h>
#import <LTKitTestUtils/LTEqualityExamples.h>

#import "DVNEasyQuadVectorBoxing.h"
#import "DVNGeometryProviderExamples.h"
#import "DVNTestGeometryProvider.h"

SpecBegin(DVNGeometryTransformer)

__block CGAffineTransform transform;
__block id providerModelMock;
__block DVNGeometryTransformerModel *model;
__block id<LTSampleValues> samples;

beforeEach(^{
  transform = CGAffineTransformTranslate(CGAffineTransformMakeScale(1, 2), 3, 4);
  providerModelMock = OCMProtocolMock(@protocol(DVNGeometryProviderModel));
  model = [[DVNGeometryTransformerModel alloc] initWithGeometryProviderModel:providerModelMock
                                                                   transform:transform];
  NSOrderedSet *keys = [NSOrderedSet orderedSetWithObject:@"foo"];
  LTParameterizationKeyToValues *mapping =
      [[LTParameterizationKeyToValues alloc] initWithKeys:keys
                                             valuesPerKey:(cv::Mat1g(1, 2) << 1, 2)];
  samples = [[LTSampleValues alloc] initWithSampledParametricValues:{0, 1} mapping:mapping];
});

afterEach(^{
  samples = nil;
  model = nil;
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    expect(model).toNot.beNil();
    expect(model.model).to.equal(providerModelMock);
    expect(CGAffineTransformEqualToTransform(model.transform, transform)).to.beTruthy();
  });
});

itShouldBehaveLike(kLTEqualityExamples, ^{
  DVNGeometryTransformerModel *model =
      [[DVNGeometryTransformerModel alloc] initWithGeometryProviderModel:providerModelMock
                                                               transform:transform];
  DVNGeometryTransformerModel *equalModel =
      [[DVNGeometryTransformerModel alloc] initWithGeometryProviderModel:providerModelMock
                                                               transform:transform];
  DVNGeometryTransformerModel *differentModel =
      [[DVNGeometryTransformerModel alloc]
       initWithGeometryProviderModel:OCMProtocolMock(@protocol(DVNGeometryProviderModel))
       transform:transform];
  DVNGeometryTransformerModel *anotherDifferentModel =
      [[DVNGeometryTransformerModel alloc]
       initWithGeometryProviderModel:providerModelMock
       transform:CGAffineTransformMakeTranslation(0, 1)];
  return @{
    kLTEqualityExamplesObject: model,
    kLTEqualityExamplesEqualObject: equalModel,
    kLTEqualityExamplesDifferentObjects: @[differentModel, anotherDifferentModel]
  };
});

itShouldBehaveLike(kDVNGeometryProviderExamples, ^{
  id<DVNGeometryProviderModel> providerModel =
      [[DVNTestGeometryProviderModel alloc]
       initWithState:0 quads:{lt::Quad(CGRectMake(0, 1, 2, 3)), lt::Quad(CGRectMake(4, 5, 6, 7))}];
  DVNGeometryTransformerModel *transformerModel =
      [[DVNGeometryTransformerModel alloc] initWithGeometryProviderModel:providerModel
                                                               transform:transform];
  NSArray<NSValue *> *expectedQuads =
      DVNConvertedBoxedQuadsFromQuads({
        lt::Quad(CGRectMake(3, 10, 2, 6)), lt::Quad(CGRectMake(7, 18, 6, 14))
      });
  std::vector<NSUInteger> indices = {0, 1};
  return @{
    kDVNGeometryProviderExamplesModel: transformerModel,
    kDVNGeometryProviderExamplesSamples: samples,
    kDVNGeometryProviderExamplesExpectedQuads: expectedQuads,
    kDVNGeometryProviderExamplesExpectedIndices: $(indices)
  };
});

context(@"provider", ^{
  context(@"model", ^{
    it(@"should provide a correct updated model", ^{
      id<DVNGeometryProviderModel> providerModel =
          [[DVNTestGeometryProviderModel alloc]
           initWithState:0
           quads:{lt::Quad(CGRectMake(0, 1, 2, 3)), lt::Quad(CGRectMake(4, 5, 6, 7))}];
      DVNGeometryTransformerModel *transformerModel =
          [[DVNGeometryTransformerModel alloc] initWithGeometryProviderModel:providerModel
                                                                   transform:transform];
      id<DVNGeometryProvider> transformer = [transformerModel provider];
      [transformer valuesFromSamples:samples end:NO];
      DVNGeometryTransformerModel *model = [transformer currentModel];
      expect(model).toNot.equal(transformerModel);

      id<DVNGeometryProvider> provider = [providerModel provider];
      [provider valuesFromSamples:samples end:NO];

      DVNGeometryTransformerModel *updatedModel =
          [[DVNGeometryTransformerModel alloc] initWithGeometryProviderModel:[provider currentModel]
                                                                   transform:transform];
      expect(model).to.equal(updatedModel);
    });
  });
});

SpecEnd
