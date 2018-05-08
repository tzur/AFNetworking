// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNPhotoKitImageAsset.h"

#import <AVFoundation/AVFoundation.h>

#import "NSError+Photons.h"
#import "PTNImageMetadata.h"
#import "PTNPhotoKitTestUtils.h"
#import "PTNTestResources.h"

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
  context(@"common", ^{
    it(@"should err when empty content editing input is received", ^{
      photoKitAsset = PTNPhotoKitCreateAssetForContentEditing(@"foo", nil, nil, 0);
      asset = [[PTNPhotoKitImageAsset alloc] initWithImage:image asset:photoKitAsset];

      expect([asset fetchImageMetadata]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetMetadataLoadingFailed;
      });
    });

    it(@"should cancel metadata request upon disposal", ^{
      photoKitAsset = PTNPhotoKitCreateAssetForContentEditing(@"foo", nil, nil, 1337);
      OCMExpect([photoKitAsset cancelContentEditingInputRequest:1337]);
      asset = [[PTNPhotoKitImageAsset alloc] initWithImage:image asset:photoKitAsset];

      [[asset fetchImageMetadata] subscribeNext:^(id __unused x) {}];

      OCMVerifyAllWithDelay(photoKitAsset, 1);
    });

    it(@"should err when invalid media type is given", ^{
      PHContentEditingInput *contentEditingInput = OCMClassMock(PHContentEditingInput.class);
      OCMStub(contentEditingInput.mediaType).andReturn(PHAssetMediaTypeAudio);
      photoKitAsset = PTNPhotoKitCreateAssetForContentEditing(@"foo", contentEditingInput, nil, 0);
      asset = [[PTNPhotoKitImageAsset alloc] initWithImage:image asset:photoKitAsset];

      expect([asset fetchImageMetadata]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetMetadataLoadingFailed;
      });
    });
  });

  context(@"image media type", ^{
    it(@"should fetch metadata", ^{
      NSURL *url = PTNImageWithMetadataURL();
      PHContentEditingInput *contentEditingInput = PTNPhotoKitCreateImageContentEditingInput(url);
      photoKitAsset = PTNPhotoKitCreateAssetForContentEditing(@"foo", contentEditingInput, nil, 0);
      asset = [[PTNPhotoKitImageAsset alloc] initWithImage:image asset:photoKitAsset];

      expect([asset fetchImageMetadata]).will.matchValue(0, ^BOOL(PTNImageMetadata *metadata) {
        return metadata != nil;
      });
    });

    it(@"should err when requesting metadata of non existing asset", ^{
      NSURL *url = [NSURL fileURLWithPath:@"/foo/bar/baz.jpg"];
      PHContentEditingInput *contentEditingInput = PTNPhotoKitCreateImageContentEditingInput(url);
      photoKitAsset = PTNPhotoKitCreateAssetForContentEditing(@"foo", contentEditingInput, nil, 0);
      asset = [[PTNPhotoKitImageAsset alloc] initWithImage:image asset:photoKitAsset];

      expect([asset fetchImageMetadata]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetMetadataLoadingFailed && error.lt_underlyingError;
      });
    });

    it(@"should err when content editing fullSizeImageURL key is nil", ^{
      PHContentEditingInput *contentEditingInput = PTNPhotoKitCreateImageContentEditingInput(nil);
      photoKitAsset = PTNPhotoKitCreateAssetForContentEditing(@"foo", contentEditingInput, nil, 0);
      asset = [[PTNPhotoKitImageAsset alloc] initWithImage:image asset:photoKitAsset];

      expect([asset fetchImageMetadata]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetMetadataLoadingFailed && error.lt_underlyingError;
      });
    });
  });

  context(@"video media type", ^{
    it(@"should fetch empty metadata", ^{
      AVAsset *avAsset = OCMClassMock(AVAsset.class);
      PHContentEditingInput *contentEditingInput =
          PTNPhotoKitCreateVideoContentEditingInput(avAsset);
      photoKitAsset = PTNPhotoKitCreateAssetForContentEditing(@"foo", contentEditingInput, nil, 0);
      asset = [[PTNPhotoKitImageAsset alloc] initWithImage:image asset:photoKitAsset];

      expect([asset fetchImageMetadata]).will.sendValues(@[[[PTNImageMetadata alloc] init]]);
    });

    it(@"should err when content editing avAsset key is nil", ^{
      PHContentEditingInput *contentEditingInput = PTNPhotoKitCreateVideoContentEditingInput(nil);
      photoKitAsset = PTNPhotoKitCreateAssetForContentEditing(@"foo", contentEditingInput, nil, 0);
      asset = [[PTNPhotoKitImageAsset alloc] initWithImage:image asset:photoKitAsset];

      expect([asset fetchImageMetadata]).will.matchError(^BOOL(NSError *error) {
        return error.code == PTNErrorCodeAssetMetadataLoadingFailed && error.lt_underlyingError;
      });
    });
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
