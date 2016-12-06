// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import <LTEngine/LTParameterizedObjectType.h>
#import <LTEngine/LTTexture+Factory.h>

#import "DVNSplineRenderer.h"
#import "DVNSplineRenderingExamples.h"
#import "DVNTestPipelineConfiguration.h"

SpecBegin(DVNSplineRenderer)

[LTParameterizedObjectType enumerateEnumUsingBlock:^(LTParameterizedObjectType *type) {
  if ([type isEqual:$(LTParameterizedObjectTypeDegenerate)]) {
    return;
  }
  
  itShouldBehaveLike(kDVNSplineRenderingExamples, ^{
    return @{
      kDVNSplineRenderingExamplesDictionary : ^NSDictionary *() {
        NSMutableDictionary *dictionary =
            [DVNTestDictionaryForType(type) mutableCopy];
        id<DVNSplineRenderingDelegate> delegate =
            OCMProtocolMock(@protocol(DVNSplineRenderingDelegate));
        id<DVNSplineRenderingDelegate> strictDelegate =
            OCMStrictProtocolMock(@protocol(DVNSplineRenderingDelegate));
        DVNPipelineConfiguration *configuration = DVNTestPipelineConfiguration();
        
        dictionary[kDVNSplineRenderingExamplesPipelineConfiguration] = configuration;
        dictionary[kDVNSplineRenderingExamplesRendererWithoutDelegate] =
        [[DVNSplineRenderer alloc] initWithType:dictionary[kDVNSplineRenderingExamplesType]
                                  configuration:configuration delegate:nil];
        dictionary[kDVNSplineRenderingExamplesRendererWithDelegate] =
        [[DVNSplineRenderer alloc] initWithType:dictionary[kDVNSplineRenderingExamplesType]
                                  configuration:configuration delegate:delegate];
        dictionary[kDVNSplineRenderingExamplesRendererWithStrictDelegate] =
        [[DVNSplineRenderer alloc] initWithType:dictionary[kDVNSplineRenderingExamplesType]
                                  configuration:configuration delegate:strictDelegate];
        dictionary[kDVNSplineRenderingExamplesStrictDelegateMock] = strictDelegate;
        dictionary[kDVNSplineRenderingExamplesTexture] =
            [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(16)];
        dictionary[kDVNSplineRenderingExamplesDelegateMock] = delegate;
        return dictionary;
      }
    };
  });
}];

SpecEnd
