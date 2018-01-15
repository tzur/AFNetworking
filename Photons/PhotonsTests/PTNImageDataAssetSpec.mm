// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "PTNImageDataAsset.h"

#import "NSError+Photons.h"
#import "PTNImageMetadata.h"

SpecBegin(PTNImageDataAsset)

__block NSData *data;
__block PTNImageDataAsset *asset;

beforeEach(^{
  char buffer[] = { 0x1, 0x2, 0x3, 0x4 };
  data = [[NSData alloc] initWithBytes:buffer length:sizeof(buffer)];
  asset = [[PTNImageDataAsset alloc] initWithData:data
                                   uniformTypeIdentifier:@"public.type"];
});

it(@"should fetch data", ^{
  expect([asset fetchData]).to.sendValues(@[data]);
});

context(@"metadata fetching", ^{
  it(@"should fetch metadata", ^{
    NSURL *url = [NSBundle.lt_testBundle URLForResource:@"PTNImageMetadataImage"
                                          withExtension:@"jpg"];

    NSData *imageData = [NSData dataWithContentsOfURL:url];
    asset = [[PTNImageDataAsset alloc] initWithData:imageData];
    expect([asset fetchImageMetadata]).will.matchValue(0, ^BOOL(PTNImageMetadata *metadata) {
      return metadata != nil;
    });
  });

  it(@"should err when data is corrupted", ^{
    expect([asset fetchImageMetadata]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetMetadataLoadingFailed && error.lt_underlyingError;
    });
  });
});

SpecEnd
