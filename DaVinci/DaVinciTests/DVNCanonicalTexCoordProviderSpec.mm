// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNCanonicalTexCoordProvider.h"

#import <LTEngine/LTQuad.h>
#import <LTKitTestUtils/LTEqualityExamples.h>

#import "DVNTexCoordProviderExamples.h"

SpecBegin(DVNCanonicalTexCoordProvider)

__block NSArray<LTQuad *> *inputQuads;
__block NSArray<LTQuad *> *additionalInputQuads;
__block LTQuad *canonicalQuad;
__block DVNCanonicalTexCoordProviderModel *model;

beforeEach(^{
  inputQuads = @[[LTQuad quadFromRect:CGRectFromSize(CGSizeMakeUniform(1))],
                 [LTQuad quadFromRect:CGRectMake(0.2, 0.8, 1, 2)]];
  LTQuadCorners corners{{CGPointZero, CGPointMake(0.2, 0.4), CGPointMake(0.1, 0.8),
    CGPointMake(0, 0.1)
  }};
  additionalInputQuads = @[[[LTQuad alloc] initWithCorners:corners]];
  canonicalQuad = [LTQuad quadFromRect:CGRectFromSize(CGSizeMakeUniform(1))];
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    model = [[DVNCanonicalTexCoordProviderModel alloc] init];
    expect(model).toNot.beNil();
  });
});

itShouldBehaveLike(kLTEqualityExamples, ^{
  DVNCanonicalTexCoordProviderModel *model = [[DVNCanonicalTexCoordProviderModel alloc] init];
  DVNCanonicalTexCoordProviderModel *equalModel = [[DVNCanonicalTexCoordProviderModel alloc] init];
  return @{
    kLTEqualityExamplesObject: model,
    kLTEqualityExamplesEqualObject: equalModel,
    kLTEqualityExamplesDifferentObjects: @[[[NSObject alloc] init]]
  };
});

itShouldBehaveLike(kDVNTexCoordProviderExamples, ^{
  return @{
    kDVNTexCoordProviderExamplesModel: model,
    kDVNTexCoordProviderExamplesInputQuads: inputQuads,
    kDVNTexCoordProviderExamplesExpectedQuads: @[canonicalQuad, canonicalQuad],
    kDVNTexCoordProviderExamplesAdditionalInputQuads: additionalInputQuads,
    kDVNTexCoordProviderExamplesAdditionalExpectedQuads: @[canonicalQuad]
  };
});

context(@"provider", ^{
  context(@"model", ^{
    it(@"should provide a correct updated model", ^{
      id<DVNTexCoordProvider> provider = [model provider];
      [provider textureMapQuadsForQuads:{lt::Quad(CGRectMake(0, 0.1, 0.4, 0.5))}];
      DVNCanonicalTexCoordProviderModel *currentModel = [provider currentModel];
      expect(currentModel).to.equal(model);
    });
  });
});

SpecEnd
