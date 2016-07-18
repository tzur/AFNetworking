// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNGeometryTransformer.h"

#import <LTEngine/LTParameterizationKeyToValues.h>
#import <LTEngine/LTSampleValues.h>
#import <LTEngineTests/LTEasyVectorBoxing.h>
#import <LTKitTests/LTEqualityExamples.h>

#import "DVNGeometryProviderExamples.h"

@interface DVNTestGeometryProviderModel : NSObject <DVNGeometryProviderModel>
- (instancetype)initWithState:(NSUInteger)state;
@property (readonly, nonatomic) NSUInteger state;
@end

@interface DVNTestGeometryProvider : NSObject <DVNGeometryProvider>
- (instancetype)initWithState:(NSUInteger)state;
@property (readonly, nonatomic) NSUInteger state;
@end

@implementation DVNTestGeometryProvider

- (instancetype)initWithState:(NSUInteger)state {
  if (self = [super init]) {
    _state = state;
  }
  return self;
}

- (dvn::GeometryValues)valuesFromSamples:(id<LTSampleValues>)samples end:(__unused BOOL)end {
  _state++;
  return dvn::GeometryValues({lt::Quad(CGRectMake(0, 1, 2, 3)), lt::Quad(CGRectMake(4, 5, 6, 7))},
                             {0, 1}, samples);
}

- (id<DVNGeometryProviderModel>)currentModel {
  return [[DVNTestGeometryProviderModel alloc] initWithState:self.state];
}

@end

@implementation DVNTestGeometryProviderModel

- (instancetype)initWithState:(NSUInteger)state {
  if (self = [super init]) {
    _state = state;
  }
  return self;
}

- (BOOL)isEqual:(DVNTestGeometryProviderModel *)model {
  if (self == model) {
    return YES;
  }

  if (![model isKindOfClass:[DVNTestGeometryProviderModel class]]) {
    return NO;
  }

  return self.state == model.state;
}

- (instancetype)copyWithZone:(NSZone __unused *)zone {
  return self;
}

- (id<DVNGeometryProvider>)provider {
  return [[DVNTestGeometryProvider alloc] initWithState:self.state];
}

@end

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
      [[DVNTestGeometryProviderModel alloc] initWithState:0];
  DVNGeometryTransformerModel *transformerModel =
      [[DVNGeometryTransformerModel alloc] initWithGeometryProviderModel:providerModel
                                                               transform:transform];
  LTQuad *firstExpectedQuad = [LTQuad quadFromRect:CGRectMake(3, 10, 2, 6)];
  LTQuad *secondExpectedQuad = [LTQuad quadFromRect:CGRectMake(7, 18, 6, 14)];
  std::vector<NSUInteger> indices = {0, 1};
  return @{
    kDVNGeometryProviderExamplesModel: transformerModel,
    kDVNGeometryProviderExamplesSamples: samples,
    kDVNGeometryProviderExamplesExpectedQuads: @[firstExpectedQuad, secondExpectedQuad],
    kDVNGeometryProviderExamplesExpectedIndices: $(indices)
  };
});

context(@"provider", ^{
  context(@"model", ^{
    it(@"should provide a correct updated model", ^{
      id<DVNGeometryProviderModel> providerModel =
          [[DVNTestGeometryProviderModel alloc] initWithState:0];
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
