// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNQuadAttributeProvider.h"

#import <LTEngine/LTParameterizationKeyToValues.h>
#import <LTEngine/LTQuad.h>
#import <LTEngine/LTSampleValues.h>
#import <LTKitTests/LTEqualityExamples.h>

#import "DVNAttributeProviderExamples.h"

SpecBegin(DVNQuadAttributeProvider)

__block DVNQuadAttributeProviderModel *model;

beforeEach(^{
  model = [[DVNQuadAttributeProviderModel alloc] init];
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    expect(model).toNot.beNil();
  });
});

itShouldBehaveLike(kLTEqualityExamples, ^{
  DVNQuadAttributeProviderModel *equalModel = [[DVNQuadAttributeProviderModel alloc] init];
  return @{
    kLTEqualityExamplesObject: model,
    kLTEqualityExamplesEqualObject: equalModel,
    kLTEqualityExamplesDifferentObjects: @[[[NSObject alloc] init]]
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
  LTGPUStruct *gpuStruct =
      [[LTGPUStructRegistry sharedInstance] structForName:@"DVNQuadAttributeProviderStruct"];

  std::vector<DVNQuadAttributeProviderStruct> values;

  values.insert(values.end(), 6, {{0, 0}, {1, 0}, {1, 1}, {0, 1}});
  values.insert(values.end(), 6, {{0, 0}, {2, 0}, {2, 2}, {0, 2}});

  NSData *data = [NSData dataWithBytes:values.data() length:values.size() * sizeof(values[0])];

  return @{
    kDVNAttributeProviderExamplesModel: [[DVNQuadAttributeProviderModel alloc] init],
    kDVNAttributeProviderExamplesInputQuads: @[quad, otherQuad],
    kDVNAttributeProviderExamplesInputIndices: @[@0, @1],
    kDVNAttributeProviderExamplesInputSample: samples,
    kDVNAttributeProviderExamplesExpectedData: data,
    kDVNAttributeProviderExamplesExpectedGPUStruct: gpuStruct
  };
});

context(@"provider", ^{
  context(@"model", ^{
    it(@"should provide a correct updated model", ^{
      id<DVNAttributeProvider> provider = [model provider];
      [provider attributeDataFromGeometryValues:dvn::GeometryValues()];
      DVNQuadAttributeProviderModel *currentModel = [provider currentModel];
      expect(currentModel).to.equal(model);
    });
  });
});

SpecEnd
