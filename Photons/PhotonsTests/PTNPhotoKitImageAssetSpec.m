// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNPhotoKitImageAsset.h"

#import "NSError+Photons.h"
#import "PTNPhotoKitTestUtils.h"

SpecBegin(PTNPhotoKitImageAsset)

__block UIImage *image;
__block id photoKitAsset;
__block PTNPhotoKitImageAsset *asset;

beforeEach(^{
  image = [[UIImage alloc] init];
  photoKitAsset = OCMClassMock([PHAsset class]);
  asset = [[PTNPhotoKitImageAsset alloc] initWithImage:image asset:photoKitAsset];
});

it(@"should fetch image", ^{
  expect([asset fetchImage]).to.sendValues(@[image]);
});

context(@"metadata fetching", ^{
  it(@"should fetch metadata", ^{
    NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:@"PTNImageMetadataImage"
                                                          withExtension:@"jpg"];
    PHContentEditingInput *contentEditingInput = PTNPhotoKitCreateContentEditingInput(url);
    photoKitAsset = PTNPhotoKitCreateAssetForContentEditing(@"foo", contentEditingInput, nil, 0);
    asset = [[PTNPhotoKitImageAsset alloc] initWithImage:image asset:photoKitAsset];

    expect([asset fetchImageMetadata]).will.matchValue(0, ^BOOL(PTNImageMetadata *metadata) {
      return metadata != nil;
    });
  });

  it(@"should err when empty content editing input is received", ^{
    photoKitAsset = PTNPhotoKitCreateAssetForContentEditing(@"foo", nil, nil, 0);
    asset = [[PTNPhotoKitImageAsset alloc] initWithImage:image asset:photoKitAsset];

    expect([asset fetchImageMetadata]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetMetadataLoadingFailed && error.lt_underlyingError;
    });
  });

  it(@"should err when empty content editing input is received", ^{
    photoKitAsset = PTNPhotoKitCreateAssetForContentEditing(@"foo", nil, nil, 0);
    asset = [[PTNPhotoKitImageAsset alloc] initWithImage:image asset:photoKitAsset];

    expect([asset fetchImageMetadata]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetMetadataLoadingFailed && error.lt_underlyingError;
    });
  });

  it(@"should err when content editing fullSizeImageURL key is nil", ^{
    PHContentEditingInput *contentEditingInput = PTNPhotoKitCreateContentEditingInput(nil);
    photoKitAsset = PTNPhotoKitCreateAssetForContentEditing(@"foo", contentEditingInput, nil, 0);
    asset = [[PTNPhotoKitImageAsset alloc] initWithImage:image asset:photoKitAsset];

    expect([asset fetchImageMetadata]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetMetadataLoadingFailed && error.lt_underlyingError;
    });
  });

  it(@"should err when requesting metadata of non existing asset", ^{
    NSURL *url = [NSURL fileURLWithPath:@"/foo/bar/baz.jpg"];
    PHContentEditingInput *contentEditingInput = PTNPhotoKitCreateContentEditingInput(url);
    photoKitAsset = PTNPhotoKitCreateAssetForContentEditing(@"foo", contentEditingInput, nil, 0);
    asset = [[PTNPhotoKitImageAsset alloc] initWithImage:image asset:photoKitAsset];

    expect([asset fetchImageMetadata]).will.matchError(^BOOL(NSError *error) {
      return error.code == PTNErrorCodeAssetMetadataLoadingFailed && error.lt_underlyingError;
    });
  });

  it(@"should cancel metadata request upon disposal", ^{
    photoKitAsset = PTNPhotoKitCreateAssetForContentEditing(@"foo", nil, nil, 1337);
    OCMExpect([photoKitAsset cancelContentEditingInputRequest:1337]);
    asset = [[PTNPhotoKitImageAsset alloc] initWithImage:image asset:photoKitAsset];

    [[asset fetchImageMetadata] subscribeNext:^(id __unused x) {}];

    OCMVerifyAllWithDelay(photoKitAsset, 1);
  });
});

context(@"equality", ^{
  __block PTNPhotoKitImageAsset *firstImage;
  __block PTNPhotoKitImageAsset *secondImage;
  __block PTNPhotoKitImageAsset *otherImage;

  beforeEach(^{
    firstImage = [[PTNPhotoKitImageAsset alloc] initWithImage:image asset:photoKitAsset];
    secondImage = [[PTNPhotoKitImageAsset alloc] initWithImage:image asset:photoKitAsset];
    otherImage = [[PTNPhotoKitImageAsset alloc] initWithImage:[[UIImage alloc] init]
                                                        asset:OCMClassMock([PHAsset class])];
  });

  it(@"should handle isEqual correctly", ^{
    expect(firstImage).to.equal(secondImage);
    expect(secondImage).to.equal(firstImage);

    expect(firstImage).notTo.equal(otherImage);
    expect(secondImage).notTo.equal(otherImage);
  });

  it(@"should create proper hash", ^{
    expect(firstImage.hash).to.equal(secondImage.hash);
  });
});

SpecEnd
