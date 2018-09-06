// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import <LTEngine/LTGLKitExtensions.h>
#import <LTEngine/LTParameterizationKeyToValues.h>
#import <LTEngine/LTSampleValues.h>
#import <LTEngineTests/LTEasyVectorBoxing.h>
#import <LTKitTestUtils/LTEqualityExamples.h>

#import "DVNEasyQuadVectorBoxing.h"
#import "DVNGeometryProviderExamples.h"
#import "DVNProjectiveGeometryTransformerModel.h"
#import "DVNTestGeometryProvider.h"

SpecBegin(DVNProjectiveGeometryTransformerModel)

__block GLKMatrix3 transform;
__block id providerModelMock;
__block DVNProjectiveGeometryTransformerModel *model;
__block id<LTSampleValues> samples;

beforeEach(^{
  transform = GLKMatrix3Multiply(GLKMatrix3MakeScale(1, 2, 1), GLKMatrix3MakeTranslation(3, 4));
  providerModelMock = OCMProtocolMock(@protocol(DVNGeometryProviderModel));
  model = [[DVNProjectiveGeometryTransformerModel alloc]
           initWithGeometryProviderModel:providerModelMock transform:transform];
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

    for (NSUInteger i = 0; i < 9; ++i) {
      expect(model.transform.m[i]).to.equal(transform.m[i]);
    }
  });
});

itShouldBehaveLike(kLTEqualityExamples, ^{
  DVNProjectiveGeometryTransformerModel *model =
      [[DVNProjectiveGeometryTransformerModel alloc] initWithGeometryProviderModel:providerModelMock
                                                               transform:transform];
  DVNProjectiveGeometryTransformerModel *equalModel =
      [[DVNProjectiveGeometryTransformerModel alloc] initWithGeometryProviderModel:providerModelMock
                                                               transform:transform];
  DVNProjectiveGeometryTransformerModel *differentModel =
      [[DVNProjectiveGeometryTransformerModel alloc]
       initWithGeometryProviderModel:OCMProtocolMock(@protocol(DVNGeometryProviderModel))
       transform:transform];
  DVNProjectiveGeometryTransformerModel *anotherDifferentModel =
      [[DVNProjectiveGeometryTransformerModel alloc]
       initWithGeometryProviderModel:providerModelMock
       transform:GLKMatrix3MakeTranslation(0, 1)];
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
  DVNProjectiveGeometryTransformerModel *transformerModel =
      [[DVNProjectiveGeometryTransformerModel alloc] initWithGeometryProviderModel:providerModel
                                                                         transform:transform];
  return @{
    kDVNGeometryProviderExamplesModel: transformerModel,
    kDVNGeometryProviderExamplesSamples: samples
  };
});

itShouldBehaveLike(kDVNDeterministicGeometryProviderExamples, ^{
  id<DVNGeometryProviderModel> providerModel =
      [[DVNTestGeometryProviderModel alloc]
       initWithState:0 quads:{lt::Quad(CGRectMake(0, 1, 2, 3)), lt::Quad(CGRectMake(4, 5, 6, 7))}];
  DVNProjectiveGeometryTransformerModel *transformerModel =
      [[DVNProjectiveGeometryTransformerModel alloc] initWithGeometryProviderModel:providerModel
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
      DVNProjectiveGeometryTransformerModel *transformerModel =
          [[DVNProjectiveGeometryTransformerModel alloc] initWithGeometryProviderModel:providerModel
                                                                             transform:transform];
      id<DVNGeometryProvider> transformer = [transformerModel provider];
      [transformer valuesFromSamples:samples end:NO];
      DVNProjectiveGeometryTransformerModel *model = [transformer currentModel];
      expect(model).toNot.equal(transformerModel);

      id<DVNGeometryProvider> provider = [providerModel provider];
      [provider valuesFromSamples:samples end:NO];

      DVNProjectiveGeometryTransformerModel *updatedModel =
          [[DVNProjectiveGeometryTransformerModel alloc]
           initWithGeometryProviderModel:[provider currentModel] transform:transform];
      expect(model).to.equal(updatedModel);
    });
  });
});

SpecEnd
