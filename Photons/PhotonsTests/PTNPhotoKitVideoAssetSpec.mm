// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "PTNPhotoKitVideoAsset.h"

SpecBegin(PTNPhotoKitVideoAsset)

__block id avasset;

beforeEach(^{
  avasset = OCMClassMock([AVAsset class]);
});

it(@"should fetch AVAsset", ^{
  PTNPhotoKitVideoAsset *videoAsset = [[PTNPhotoKitVideoAsset alloc] initWithAVAsset:avasset];
  expect([videoAsset fetchAVAsset]).to.sendValues(@[avasset]);
});

context(@"equality", ^{
  __block PTNPhotoKitVideoAsset *firstAsset;
  __block PTNPhotoKitVideoAsset *secondAsset;
  __block PTNPhotoKitVideoAsset *otherAsset;

  beforeEach(^{
    firstAsset = [[PTNPhotoKitVideoAsset alloc] initWithAVAsset:avasset];
    secondAsset = [[PTNPhotoKitVideoAsset alloc] initWithAVAsset:avasset];
    otherAsset = [[PTNPhotoKitVideoAsset alloc] initWithAVAsset:OCMClassMock([AVAsset class])];
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
