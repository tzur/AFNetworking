// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNCacheImageAsset.h"

#import "PTNCacheInfo.h"

/// Single protocol encapsulating both \c PTNImageAsset and \c PTNDataAsset as a workaround to
/// \c OCMock's lack of support in mocks of multiple protocols.
@protocol PTNDataImageAsset <PTNImageAsset, PTNDataAsset>
@end

SpecBegin(PTNCacheImageAsset)

__block id<PTNImageAsset, PTNDataAsset> underlyingAsset;
__block PTNCacheInfo *cacheInfo;

beforeEach(^{
  underlyingAsset = OCMProtocolMock(@protocol(PTNDataImageAsset));
  cacheInfo = [[PTNCacheInfo alloc] initWithMaxAge:1337 entityTag:@"foo"];
});

it(@"should initialize with underlying asset and cache info", ^{
  PTNCacheImageAsset *asset = [PTNCacheImageAsset imageAssetWithUnderlyingAsset:underlyingAsset
                                                                    cacheInfo:cacheInfo];

  expect(asset.underlyingAsset).equal(underlyingAsset);
  expect(asset.cacheInfo).equal(cacheInfo);
});

it(@"should initialize proxy image asset methods to underlying asset", ^{
  RACSignal *imageSignal = [[RACSignal alloc] init];
  RACSignal *metadataSignal = [[RACSignal alloc] init];
  OCMStub([underlyingAsset fetchImage]).andReturn(imageSignal);
  OCMStub([underlyingAsset fetchImageMetadata]).andReturn(metadataSignal);

  PTNCacheImageAsset *asset = [PTNCacheImageAsset imageAssetWithUnderlyingAsset:underlyingAsset
                                                                      cacheInfo:cacheInfo];

  expect(asset.fetchImage).equal(imageSignal);
  expect(asset.fetchImageMetadata).equal(metadataSignal);
});

context(@"equality", ^{
  __block PTNCacheImageAsset *firstAsset;
  __block PTNCacheImageAsset *secondAsset;
  __block PTNCacheImageAsset *otherAsset;

  beforeEach(^{
    id<PTNImageAsset, PTNDataAsset> otherUnderlyingAsset =
        OCMProtocolMock(@protocol(PTNDataImageAsset));
    PTNCacheInfo *otherCacheInfo = [[PTNCacheInfo alloc] initWithMaxAge:0 entityTag:@"bar"];

    firstAsset = [PTNCacheImageAsset imageAssetWithUnderlyingAsset:underlyingAsset
                                                         cacheInfo:cacheInfo];
    secondAsset = [PTNCacheImageAsset imageAssetWithUnderlyingAsset:underlyingAsset
                                                          cacheInfo:cacheInfo];
    otherAsset = [PTNCacheImageAsset imageAssetWithUnderlyingAsset:otherUnderlyingAsset
                                                         cacheInfo:otherCacheInfo];
  });

  it(@"should handle isEqual correctly", ^{
    expect(firstAsset).to.equal(secondAsset);
    expect(secondAsset).to.equal(firstAsset);

    expect(firstAsset).notTo.equal(otherAsset);
    expect(secondAsset).notTo.equal(otherAsset);
  });

  it(@"should create proper hash", ^{
    expect(firstAsset.hash).to.equal(secondAsset.hash);
  });
});

SpecEnd
