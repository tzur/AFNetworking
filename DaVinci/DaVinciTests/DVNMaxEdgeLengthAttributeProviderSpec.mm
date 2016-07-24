// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNMaxEdgeLengthAttributeProvider.h"

#import <LTEngine/LTParameterizationKeyToValues.h>
#import <LTEngine/LTQuad.h>
#import <LTEngine/LTSampleValues.h>
#import <LTKitTests/LTEqualityExamples.h>

#import "DVNAttributeProviderExamples.h"

SpecBegin(DVNMaxEdgeLengthAttributeProvider)

__block DVNMaxEdgeLengthAttributeProviderModel *model;

beforeEach(^{
  model = [[DVNMaxEdgeLengthAttributeProviderModel alloc] init];
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    expect(model).toNot.beNil();
  });
});

itShouldBehaveLike(kLTEqualityExamples, ^{
  DVNMaxEdgeLengthAttributeProviderModel *equalModel =
      [[DVNMaxEdgeLengthAttributeProviderModel alloc] init];
  return @{
    kLTEqualityExamplesObject: model,
    kLTEqualityExamplesEqualObject: equalModel,
    kLTEqualityExamplesDifferentObjects: @[]
  };
});

itShouldBehaveLike(kDVNAttributeProviderExamples, ^{
  LTQuad *quad = [LTQuad quadFromRect:CGRectFromSize(CGSizeMakeUniform(1))];
  LTQuad *otherQuad = [LTQuad quadFromRect:CGRectFromSize(CGSizeMakeUniform(2))];
  NSOrderedSet<NSString *> *keys = [NSOrderedSet orderedSetWithObject:@[@"foo"]];
  LTParameterizationKeyToValues *mapping =
      [[LTParameterizationKeyToValues alloc] initWithKeys:keys
                                             valuesPerKey:(cv::Mat1g(1, 2) << 1, 2)];
  LTSampleValues *samples =
      [[LTSampleValues alloc] initWithSampledParametricValues:{0, 1} mapping:mapping];
  LTGPUStruct *gpuStruct = [[LTGPUStructRegistry sharedInstance]
                            structForName:@"DVNMaxEdgeLengthAttributeProviderStruct"];

  std::vector<DVNMaxEdgeLengthAttributeProviderStruct> values;

  values.insert(values.end(), 6, {1});
  values.insert(values.end(), 6, {2});

  NSData *data = [NSData dataWithBytes:values.data() length:values.size() * sizeof(values[0])];

  return @{
    kDVNAttributeProviderExamplesModel: [[DVNMaxEdgeLengthAttributeProviderModel alloc] init],
    kDVNAttributeProviderExamplesInputQuads: @[quad, otherQuad],
    kDVNAttributeProviderExamplesInputIndices: @[@0, @1],
    kDVNAttributeProviderExamplesInputSample: samples,
    kDVNAttributeProviderExamplesExpectedData: data,
    kDVNAttributeProviderExamplesExpectedGPUStruct: gpuStruct
  };
});

context(@"sample attribute data", ^{
});

context(@"provider", ^{
  context(@"model", ^{
    it(@"should provide a correct updated model", ^{
      id<DVNAttributeProvider> provider = [model provider];
      [provider attributeDataFromGeometryValues:dvn::GeometryValues()];
      DVNMaxEdgeLengthAttributeProviderModel *currentModel = [provider currentModel];
      expect(currentModel).to.equal(model);
    });
  });
});

SpecEnd
