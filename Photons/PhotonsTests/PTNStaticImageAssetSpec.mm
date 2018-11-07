// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNStaticImageAsset.h"

#import "PTNImageMetadata.h"

SpecBegin(PTNStaticImageAsset)

__block UIImage *image;
__block PTNImageMetadata *imageMetadata;

beforeEach(^{
  image = [[UIImage alloc] init];
  imageMetadata = [[PTNImageMetadata alloc] init];
});

it(@"should initialize with image", ^{
  PTNStaticImageAsset *asset = [[PTNStaticImageAsset alloc] initWithImage:image
                                                            imageMetadata:imageMetadata];

  expect([asset fetchImage]).to.sendValues(@[image]);
  expect([asset fetchImageMetadata]).to.sendValues(@[imageMetadata]);
});

SpecEnd
