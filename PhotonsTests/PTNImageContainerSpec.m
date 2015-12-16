// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNImageContainer.h"

#import "PTNImageMetadata.h"

SpecBegin(PTNImageContainer)

__block UIImage *imageData;

beforeEach(^{
  imageData = [[UIImage alloc] init];
});

it(@"should initialize with image", ^{
  PTNImageContainer *image = [[PTNImageContainer alloc] initWithImage:imageData];
  expect(image.image).to.equal(imageData);
  expect(image.metadata).to.beNil();
});

it(@"should initialize with image and metadata", ^{
  PTNImageContainer *image =
      [[PTNImageContainer alloc] initWithImage:imageData metadata:[[PTNImageMetadata alloc] init]];
  expect(image.image).to.equal(imageData);
  expect(image.metadata).to.equal([[PTNImageMetadata alloc] init]);
});

context(@"equality", ^{
  __block PTNImageContainer *firstImage;
  __block PTNImageContainer *secondImage;
  __block PTNImageContainer *otherImage;

  beforeEach(^{
    id metadata = [[PTNImageMetadata alloc] initWithMetadataDictionary:@{@"foo" : @"bar"}];

    firstImage = [[PTNImageContainer alloc] initWithImage:imageData metadata:metadata];
    secondImage = [[PTNImageContainer alloc] initWithImage:imageData metadata:metadata];
    otherImage = [[PTNImageContainer alloc] initWithImage:imageData];
  });

  it(@"should handle isEqual correctly", ^{
    expect(firstImage).to.equal(secondImage);
    expect(secondImage).to.equal(firstImage);

    expect(firstImage).notTo.equal(otherImage);
    expect(secondImage).notTo.equal(otherImage);
  });

  it(@"should create proper hash", ^{
    expect(firstImage.hash).to.equal(secondImage.hash);

    expect(firstImage.hash).notTo.equal(otherImage.hash);
    expect(secondImage.hash).notTo.equal(otherImage.hash);
  });
});

SpecEnd
