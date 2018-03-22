// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushRenderConfigurationProvider.h"

#import <LTEngine/LTTexture.h>

#import "DVNBrushModel.h"
#import "DVNBrushModelVersion+TestBrushModel.h"
#import "DVNBrushRenderModel.h"
#import "DVNBrushRenderTargetInformation.h"

static const CGSize kTextureSize = CGSizeMakeUniform(100);

NSDictionary<NSString *, LTTexture *> *
    DVNTestTextureMappingForVersion(DVNBrushModelVersion *version) {
  NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
  for (NSString *key in [[version classOfBrushModel] imageURLPropertyKeys]) {
    LTTexture *texture = OCMClassMock([LTTexture class]);
    OCMStub([texture size]).andReturn(kTextureSize);
    dictionary[key] = texture;
  }
  return dictionary;
}

static NSString * const kDVNBrushRenderConfigurationProviderExamples =
    @"DVNBrushRenderConfigurationProviderExamples";
static NSString * const kDVNBrushRenderConfigurationProviderExamplesBrushRenderModel =
    @"DVNBrushRenderConfigurationProviderExamplesBrushRenderModel";
static NSString * const kDVNBrushRenderConfigurationProviderExamplesTextureMapping =
    @"DVNBrushRenderConfigurationProviderExamplesTextureMapping";

SharedExamplesBegin(DVNBrushRenderConfigurationProviderExamples)

sharedExamplesFor(kDVNBrushRenderConfigurationProviderExamples, ^(NSDictionary *data) {
  __block DVNBrushRenderModel *model;
  __block DVNBrushRenderConfigurationProvider *provider;

  beforeEach(^{
    model = data[kDVNBrushRenderConfigurationProviderExamplesBrushRenderModel];
    provider = [[DVNBrushRenderConfigurationProvider alloc] init];
  });

  it(@"should construct valid brush render configuration", ^{
    NSDictionary<NSString *, LTTexture *> *textureMapping =
        data[kDVNBrushRenderConfigurationProviderExamplesTextureMapping];
    DVNPipelineConfiguration *pipelineConfiguration =
        [provider configurationForModel:model withTextureMapping:textureMapping];
    expect(pipelineConfiguration).toNot.beNil();
  });
});

SharedExamplesEnd

SpecBegin(DVNBrushRenderConfigurationProvider)

context(@"creation", ^{
  for (DVNBrushModelVersion *version in [DVNBrushModelVersion fields]) {
    itShouldBehaveLike(kDVNBrushRenderConfigurationProviderExamples, ^{
      DVNBrushModel *brushModel = [version testBrushModel];
      DVNBrushRenderTargetInformation *info =
          [DVNBrushRenderTargetInformation
           instanceWithRenderTargetLocation:lt::Quad::canonicalSquare()
           renderTargetHasSingleChannel:NO
           renderTargetIsNonPremultiplied:NO];
      DVNBrushRenderModel *model = [DVNBrushRenderModel instanceWithBrushModel:brushModel
                                                              renderTargetInfo:info
                                                              conversionFactor:0.7];
      return @{
        kDVNBrushRenderConfigurationProviderExamplesBrushRenderModel: model,
        kDVNBrushRenderConfigurationProviderExamplesTextureMapping:
            DVNTestTextureMappingForVersion(version)
      };
    });
  }
});

SpecEnd
