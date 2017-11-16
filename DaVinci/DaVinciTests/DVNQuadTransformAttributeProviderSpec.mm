// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNQuadTransformAttributeProvider.h"

#import <LTEngine/LTParameterizationKeyToValues.h>
#import <LTEngine/LTQuad.h>
#import <LTEngine/LTRotatedRect.h>
#import <LTEngine/LTSampleValues.h>
#import <LTKitTestUtils/LTEqualityExamples.h>

#import "DVNAttributeProviderExamples.h"

/// Group name of shared tests for \c DVNQuadTransformAttributeProviderModel objects.
NSString * const kDVNQuadTransformAttributeProviderExamples =
    @"DVNQuadTransformAttributeProviderExamples";

/// Dictionary key to the \c isInverse value that is given upon initialization to the test object.
NSString * const kDVNQuadTransformAttributeProviderIsInverse =
    @"DVNQuadTransformAttributeProviderIsInverse";

SharedExamplesBegin(DVNQuadTransformAttributeProviderExamples)

sharedExamplesFor(kDVNQuadTransformAttributeProviderExamples, ^(NSDictionary *data) {
  __block DVNQuadTransformAttributeProviderModel *model;
  __block NSNumber *isInverse;

  beforeEach(^{
    isInverse = data[kDVNQuadTransformAttributeProviderIsInverse];
    model = [[DVNQuadTransformAttributeProviderModel alloc] initWithIsInverse:isInverse.boolValue];
  });

  context(@"initialization", ^{
    it(@"should initialize correctly", ^{
      expect(model).toNot.beNil();
    });
  });

  itShouldBehaveLike(kLTEqualityExamples, ^{
    DVNQuadTransformAttributeProviderModel *equalModel =
        [[DVNQuadTransformAttributeProviderModel alloc] initWithIsInverse:isInverse.boolValue];
    return @{
      kLTEqualityExamplesObject: model,
      kLTEqualityExamplesEqualObject: equalModel,
      kLTEqualityExamplesDifferentObjects: @[[[NSObject alloc] init]]
    };
  });

  itShouldBehaveLike(kDVNAttributeProviderExamples, ^{
    LTQuad *quad = [LTQuad quadFromRotatedRect:[LTRotatedRect rect:CGRectMake(1, 2, 3, 4)
                                                         withAngle:0.5]];
    LTQuad *otherQuad = [LTQuad quadFromRotatedRect:[LTRotatedRect rect:CGRectMake(5, 6, 7, 8)
                                                              withAngle:0.75]];
    NSOrderedSet<NSString *> *keys = [NSOrderedSet orderedSetWithObject:@[@"foo"]];
    LTParameterizationKeyToValues *mapping = [[LTParameterizationKeyToValues alloc]
                                              initWithKeys:keys
                                              valuesPerKey:(cv::Mat1g(1, 2) << 1, 2)];
    LTSampleValues *samples = [[LTSampleValues alloc] initWithSampledParametricValues:{0, 1}
                                                                              mapping:mapping];
    LTGPUStruct *gpuStruct = [[LTGPUStructRegistry sharedInstance]
                              structForName:@"DVNQuadTransformAttributeProviderStruct"];

    std::vector<DVNQuadTransformAttributeProviderStruct> values;

    GLKMatrix3 quadTransform = quad.transform;
    GLKMatrix3 otherQuadTransform = otherQuad.transform;

    if (isInverse.boolValue) {
      quadTransform = GLKMatrix3Invert(quadTransform, NULL);
      otherQuadTransform = GLKMatrix3Invert(otherQuadTransform, NULL);
    }

    values.insert(values.end(), 6, {
      GLKMatrix3GetRow(quadTransform, 0),
      GLKMatrix3GetRow(quadTransform, 1),
      GLKMatrix3GetRow(quadTransform, 2)
    });
    values.insert(values.end(), 6, {
      GLKMatrix3GetRow(otherQuadTransform, 0),
      GLKMatrix3GetRow(otherQuadTransform, 1),
      GLKMatrix3GetRow(otherQuadTransform, 2)
    });

    NSData *data = [NSData dataWithBytes:values.data() length:values.size() * sizeof(values[0])];

    return @{
      kDVNAttributeProviderExamplesModel: [[DVNQuadTransformAttributeProviderModel alloc]
                                           initWithIsInverse:isInverse.boolValue],
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
        DVNQuadTransformAttributeProviderModel *currentModel = [provider currentModel];
        expect(currentModel).to.equal(model);
      });
    });
  });
});

SharedExamplesEnd

SpecBegin(DVNQuadTransformAttributeProvider)

itShouldBehaveLike(kDVNQuadTransformAttributeProviderExamples, ^{
  return @{kDVNQuadTransformAttributeProviderIsInverse: @YES};
});

itShouldBehaveLike(kDVNQuadTransformAttributeProviderExamples, ^{
  return @{kDVNQuadTransformAttributeProviderIsInverse: @NO};
});

SpecEnd
