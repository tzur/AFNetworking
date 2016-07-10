// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNTexCoordProviderExamples.h"

#import <LTEngine/LTQuad.h>

#import "DVNTexCoordProvider.h"

NSString * const kDVNTexCoordProviderExamples = @"DVNTexCoordProviderExamples";
NSString * const kDVNTexCoordProviderExamplesModel = @"DVNTexCoordProviderExamplesModel";
NSString * const kDVNTexCoordProviderExamplesInputQuads = @"DVNTexCoordProviderExamplesInputQuads";
NSString * const kDVNTexCoordProviderExamplesExpectedQuads =
    @"DVNTexCoordProviderExamplesExpectedQuads";
NSString * const kDVNTexCoordProviderExamplesAdditionalInputQuads =
    @"DVNTexCoordProviderExamplesAdditionalInputQuads";
NSString * const kDVNTexCoordProviderExamplesAdditionalExpectedQuads =
    @"DVNTexCoordProviderExamplesAdditionalExpectedQuads";

std::vector<lt::Quad> DVNConvertedQuadsFromQuads(NSArray<LTQuad *> *quads) {
  std::vector<lt::Quad> convertedQuads;
  convertedQuads.reserve(quads.count);

  for (LTQuad *quad in quads) {
    convertedQuads.push_back(lt::Quad(quad.corners));
  }

  return convertedQuads;
}

NSArray<LTQuad *> *DVNConvertedQuadsFromQuads(const std::vector<lt::Quad> &quads) {
  NSMutableArray<LTQuad *> *convertedQuads = [NSMutableArray arrayWithCapacity:quads.size()];

  for (const lt::Quad &quad : quads) {
    [convertedQuads addObject:[[LTQuad alloc] initWithCorners:quad.corners()]];
  }

  return [convertedQuads copy];
}

SharedExamplesBegin(DVNTexCoordProviderExamples)

sharedExamplesFor(kDVNTexCoordProviderExamples, ^(NSDictionary *data) {
  __block id<DVNTexCoordProviderModel> model;
  __block std::vector<lt::Quad> inputQuads;
  __block NSArray<LTQuad *> *expectedQuads;
  __block std::vector<lt::Quad> additionalInputQuads;
  __block NSArray<LTQuad *> *additionalExpectedQuads;

  beforeEach(^{
    model = data[kDVNTexCoordProviderExamplesModel];
    inputQuads = DVNConvertedQuadsFromQuads(data[kDVNTexCoordProviderExamplesInputQuads]);
    expectedQuads = data[kDVNTexCoordProviderExamplesExpectedQuads];
    additionalInputQuads =
        DVNConvertedQuadsFromQuads(data[kDVNTexCoordProviderExamplesAdditionalInputQuads]);
    additionalExpectedQuads = data[kDVNTexCoordProviderExamplesAdditionalExpectedQuads];
  });

  afterEach(^{
    additionalExpectedQuads = nil;
    additionalInputQuads = {};
    expectedQuads = nil;
    inputQuads = {};
    model = nil;
  });

  context(@"model", ^{
    it(@"should return a provider", ^{
      expect([model provider]).toNot.beNil();
    });

    it(@"should return a provider with the same model", ^{
      expect([[model provider] currentModel]).to.equal(model);
    });
  });

  context(@"provider", ^{
    __block id<DVNTexCoordProvider> provider;

    beforeEach(^{
      provider = [model provider];
    });

    afterEach(^{
      provider = nil;
    });

    context(@"providing texture map quads", ^{
      it(@"should provide the expected quads", ^{
        std::vector<lt::Quad> textureMapQuads = [provider textureMapQuadsForQuads:inputQuads];
        expect(DVNConvertedQuadsFromQuads(textureMapQuads)).to.equal(expectedQuads);
      });

      it(@"should provide the expected quads for consecutive queries", ^{
        std::vector<lt::Quad> textureMapQuads = [provider textureMapQuadsForQuads:inputQuads];
        expect(DVNConvertedQuadsFromQuads(textureMapQuads)).to.equal(expectedQuads);

        textureMapQuads = [provider textureMapQuadsForQuads:additionalInputQuads];
        expect(DVNConvertedQuadsFromQuads(textureMapQuads)).to.equal(additionalExpectedQuads);
      });

      it(@"should reproduce the same quads when using the same model", ^{
        std::vector<lt::Quad> textureMapQuads = [provider textureMapQuadsForQuads:inputQuads];
        id<DVNTexCoordProvider> otherProvider = [model provider];
        std::vector<lt::Quad> otherTextureMapQuads =
            [otherProvider textureMapQuadsForQuads:inputQuads];
        expect(textureMapQuads == otherTextureMapQuads).to.beTruthy();
      });
    });

    context(@"model", ^{
      it(@"should reproduce the same model", ^{
        [provider textureMapQuadsForQuads:inputQuads];
        id<DVNTexCoordProviderModel> currentModel = [provider currentModel];
        id<DVNTexCoordProvider> otherProvider = [model provider];
        [otherProvider textureMapQuadsForQuads:inputQuads];
        expect([otherProvider currentModel]).to.equal(currentModel);
      });
    });
  });
});

SharedExamplesEnd
