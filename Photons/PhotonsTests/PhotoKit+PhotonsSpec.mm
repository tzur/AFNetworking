// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PhotoKit+Photons.h"

#import <MobileCoreServices/MobileCoreServices.h>

#import "PTNDescriptor.h"

@interface PHAsset (UniformTypeIdentifier)
- (NSString *)uniformTypeIdentifier;
@property (readonly, nonatomic) int cloudPlaceholderKind;
@end

/// Returns a mocked PHAsset with the given \c uti.
static PHAsset *PTNCreateAsset(NSString * _Nullable uti = @"") {
  PHAsset *asset = OCMPartialMock([[PHAsset alloc] init]);
  if (uti) {
    OCMStub([asset uniformTypeIdentifier]).andReturn(uti);
  }
  return asset;
}

SpecBegin(PhotoKit_Photons)

context(@"asset descriptor", ^{
  it(@"should have no localized title", ^{
    PHAsset *asset = OCMPartialMock([[PHAsset alloc] init]);

    expect(asset.localizedTitle).to.beNil();
  });

  it(@"should not crash when retrieving filename", ^{
    PHAsset *asset = OCMPartialMock([[PHAsset alloc] init]);

    expect(asset.filename).to.beNil();
  });

  it(@"should reveal delete change capabilities", ^{
    PHAsset *asset = OCMPartialMock([[PHAsset alloc] init]);
    OCMStub([asset canPerformEditOperation:PHAssetEditOperationDelete]).andReturn(YES);

    expect(asset.descriptorCapabilities & PTNDescriptorCapabilityDelete).to.beTruthy();
  });

  it(@"should not reveal delete change capabilities when the underlying asset disallows it", ^{
    PHAsset *asset = OCMPartialMock([[PHAsset alloc] init]);
    OCMStub([asset canPerformEditOperation:PHAssetEditOperationDelete]).andReturn(NO);

    expect(asset.descriptorCapabilities & PTNDescriptorCapabilityDelete).to.beFalsy();
  });

  it(@"should reveal favorite change capabilities", ^{
    PHAsset *asset = OCMPartialMock([[PHAsset alloc] init]);

    expect(asset.descriptorCapabilities & PTNAssetDescriptorCapabilityFavorite).to.beTruthy();
  });

  it(@"should reveal cloud based traits when the underlying asset is a cloud placeholder", ^{
    PHAsset *placeholderAsset1 = PTNCreateAsset();
    OCMStub(placeholderAsset1.cloudPlaceholderKind).andReturn(3);
    expect(placeholderAsset1.descriptorTraits).to.contain(kPTNDescriptorTraitCloudBasedKey);

    PHAsset *placeholderAsset2 = PTNCreateAsset();
    OCMStub(placeholderAsset2.cloudPlaceholderKind).andReturn(4);
    expect(placeholderAsset2.descriptorTraits).to.contain(kPTNDescriptorTraitCloudBasedKey);

    PHAsset *asset = PTNCreateAsset();
    OCMStub(asset.cloudPlaceholderKind).andReturn(7);
    expect(asset.descriptorTraits).to.beEmpty();
  });

  it(@"should reveal video based traits when the underlying asset is video", ^{
    PHAsset *videoAsset = PTNCreateAsset();
    OCMStub(videoAsset.mediaType).andReturn(PHAssetMediaTypeVideo);
    expect(videoAsset.descriptorTraits).to.contain(kPTNDescriptorTraitAudiovisualKey);

    PHAsset *imageAsset = PTNCreateAsset();
    OCMStub(imageAsset.mediaType).andReturn(PHAssetMediaTypeImage);
    expect(imageAsset.descriptorTraits).to.beEmpty();

    PHAsset *asset = PTNCreateAsset();
    OCMStub(asset.mediaType).andReturn(PHAssetMediaTypeUnknown);
    expect(asset.descriptorTraits).to.beEmpty();
  });

  it(@"should reveal raw traits when the underlying asset is raw", ^{
    PHAsset *rawAsset = PTNCreateAsset(@"com.adobe.raw-image");
    expect(rawAsset.descriptorTraits).to.contain(kPTNDescriptorTraitRawKey);

    PHAsset *jpegAsset = PTNCreateAsset(@"public.image");
    expect(jpegAsset.descriptorTraits).to.beEmpty();
  });

  it(@"should reveal GIF traits when the underlying asset is a GIF", ^{
    PHAsset *gifAsset = PTNCreateAsset(@"com.compuserve.gif");
    expect(gifAsset.descriptorTraits).to.contain(kPTNDescriptorTraitGIFKey);

    PHAsset *jpegAsset = PTNCreateAsset(@"public.image");
    expect(jpegAsset.descriptorTraits).to.beEmpty();
  });

  if (@available(iOS 9.1, *)) {
    it(@"should reveal live photo trait when the underlying asset has live photo subtype", ^{
      PHAsset *imageAsset = PTNCreateAsset();
      OCMStub(imageAsset.mediaSubtypes).andReturn(PHAssetMediaSubtypePhotoHDR |
                                                  PHAssetMediaSubtypePhotoLive);
      expect(imageAsset.descriptorTraits).to.contain(kPTNDescriptorTraitLivePhotoKey);
    });
  }

  it(@"should not reveal type traits when UTI is nil", ^{
    PHAsset *asset = PTNCreateAsset(nil);
    expect(asset.descriptorTraits).to.beEmpty();
  });

  it(@"should have no artist", ^{
    PHAsset *asset = OCMPartialMock([[PHAsset alloc] init]);

    expect(asset.artist).to.beNil();
  });
});

context(@"album descriptor", ^{
  it(@"should have a localized title", ^{
    PHCollection *album = OCMPartialMock([[PHCollection alloc] init]);
    OCMStub([album localizedTitle]).andReturn(@"foo");

    expect(((id<PTNAlbumDescriptor>)album).localizedTitle).to.equal(@"foo");
  });

  it(@"should have no asset count for regular collections", ^{
    PHCollection *album = OCMPartialMock([[PHCollection alloc] init]);

    expect(album.assetCount).to.equal(PTNNotFound);
  });

  it(@"should have no asset count for collection lists", ^{
    PHCollectionList *album = OCMPartialMock([[PHCollectionList alloc] init]);

    expect(album.assetCount).to.equal(PTNNotFound);
  });

  it(@"should have an asset count for asset collection", ^{
    PHAssetCollection *album = OCMPartialMock([[PHAssetCollection alloc] init]);
    OCMStub([album estimatedAssetCount]).andReturn(1337);

    expect(album.assetCount).to.equal(1337);
  });

  it(@"should have no asset count for asset collection if no estimation exists", ^{
    PHAssetCollection *album = OCMPartialMock([[PHAssetCollection alloc] init]);
    OCMStub([album estimatedAssetCount]).andReturn(NSNotFound);

    expect(album.assetCount).to.equal(PTNNotFound);
  });

  it(@"should reveal delete change capabilities when the underlying collection allows it", ^{
    PHCollection *album = OCMPartialMock([[PHCollection alloc] init]);
    OCMStub([album canPerformEditOperation:PHCollectionEditOperationDelete]).andReturn(YES);

    expect(album.descriptorCapabilities & PTNDescriptorCapabilityDelete).to.beTruthy();
  });

  it(@"should not reveal delete change capabilities when the underlying collection disallows it", ^{
    PHCollection *album = OCMPartialMock([[PHCollection alloc] init]);
    OCMStub([album canPerformEditOperation:PHCollectionEditOperationDelete]).andReturn(NO);

    expect(album.descriptorCapabilities & PTNDescriptorCapabilityDelete).to.beFalsy();
  });

  it(@"should reveal delete change capabilities when the underlying collection allows it", ^{
    PHCollection *album = OCMPartialMock([[PHCollection alloc] init]);
    OCMStub([album canPerformEditOperation:PHCollectionEditOperationRemoveContent]).andReturn(YES);

    expect(album.albumDescriptorCapabilities & PTNDescriptorCapabilityDelete).to.beTruthy();
  });

  it(@"should not reveal delete change capabilities when the underlying collection disallows it", ^{
    PHCollection *album = OCMPartialMock([[PHCollection alloc] init]);
    OCMStub([album canPerformEditOperation:PHCollectionEditOperationRemoveContent]).andReturn(NO);

    expect(album.albumDescriptorCapabilities & PTNAlbumDescriptorCapabilityRemoveContent)
        .to.beFalsy();
  });

  it(@"should reveal no traits", ^{
    PHCollection *album = OCMPartialMock([[PHCollection alloc] init]);
    expect(album.descriptorTraits).to.equal([NSSet set]);
  });
});

SpecEnd
