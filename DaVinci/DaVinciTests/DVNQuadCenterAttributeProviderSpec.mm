// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNQuadCenterAttributeProvider.h"

#import <LTEngine/LTParameterizationKeyToValues.h>
#import <LTEngine/LTQuad.h>
#import <LTEngine/LTSampleValues.h>
#import <LTKitTestUtils/LTEqualityExamples.h>

#import "DVNAttributeProviderExamples.h"

SpecBegin(DVNQuadCenterAttributeProvider)

__block DVNQuadCenterAttributeProviderModel *model;

beforeEach(^{
  model = [[DVNQuadCenterAttributeProviderModel alloc] init];
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    expect(model).toNot.beNil();
  });
});

itShouldBehaveLike(kLTEqualityExamples, ^{
  DVNQuadCenterAttributeProviderModel *equalModel =
      [[DVNQuadCenterAttributeProviderModel alloc] init];
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
      [[LTGPUStructRegistry sharedInstance] structForName:@"DVNQuadCenterAttributeProviderStruct"];

  std::vector<DVNQuadCenterAttributeProviderStruct> values;

  values.insert(values.end(), 6, {{LTVector2(0.5)}});
  values.insert(values.end(), 6, {{LTVector2(1)}});

  NSData *data = [NSData dataWithBytes:values.data() length:values.size() * sizeof(values[0])];

  return @{
    kDVNAttributeProviderExamplesModel: [[DVNQuadCenterAttributeProviderModel alloc] init],
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
      DVNQuadCenterAttributeProviderModel *currentModel = [provider currentModel];
      expect(currentModel).to.equal(model);
    });
  });
});

SpecEnd
