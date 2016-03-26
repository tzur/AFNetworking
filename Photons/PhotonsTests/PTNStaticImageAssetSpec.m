// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNStaticImageAsset.h"

#import "PTNImageMetadata.h"

SpecBegin(PTNStaticImageAsset)

it(@"should initialize with image", ^{
  UIImage *image = [[UIImage alloc] init];
  PTNStaticImageAsset *asset = [[PTNStaticImageAsset alloc] initWithImage:image];

  expect([asset fetchImage]).to.sendValues(@[image]);
  expect([asset fetchImageMetadata]).to.sendValues(@[[[PTNImageMetadata alloc] init]]);
});

context(@"equality", ^{
  __block PTNStaticImageAsset *firstAsset;
  __block PTNStaticImageAsset *secondAsset;
  __block PTNStaticImageAsset *otherAsset;

  beforeEach(^{
    UIImage *image = [[UIImage alloc] init];
    firstAsset = [[PTNStaticImageAsset alloc] initWithImage:image];
    secondAsset = [[PTNStaticImageAsset alloc] initWithImage:image];
    otherAsset = [[PTNStaticImageAsset alloc] initWithImage:[[UIImage alloc] init]];
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
