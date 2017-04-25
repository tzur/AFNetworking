// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PhotoKit+Photons.h"

#import <MobileCoreServices/MobileCoreServices.h>

#import "PTNDescriptor.h"

@interface PHAsset (UniformTypeIdentifier)
- (NSString *)uniformTypeIdentifier;
@end

SpecBegin(PhotoKit_Photons)

context(@"asset descriptor", ^{
  it(@"should have no localized title", ^{
    PHAsset *asset = OCMPartialMock([[PHAsset alloc] init]);

    expect(asset.localizedTitle).to.beNil();
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

  it(@"should reveal cloud based traits when the underlying asset is cloud based", ^{
    PHAsset *cloudAsset = OCMPartialMock([[PHAsset alloc] init]);
    OCMStub(cloudAsset.sourceType).andReturn(PHAssetSourceTypeCloudShared);
    expect(cloudAsset.descriptorTraits).to.contain(kPTNDescriptorTraitCloudBasedKey);

    PHAsset *iTunesAsset = OCMPartialMock([[PHAsset alloc] init]);
    OCMStub(iTunesAsset.sourceType).andReturn(PHAssetSourceTypeiTunesSynced);
    expect(iTunesAsset.descriptorTraits).to.equal([NSSet set]);

    PHAsset *asset = OCMPartialMock([[PHAsset alloc] init]);
    OCMStub(asset.sourceType).andReturn(PHAssetSourceTypeUserLibrary);
    expect(asset.descriptorTraits).to.equal([NSSet set]);
  });

  it(@"should reveal video based traits when the underlying asset is video", ^{
    PHAsset *videoAsset = OCMPartialMock([[PHAsset alloc] init]);
    OCMStub(videoAsset.mediaType).andReturn(PHAssetMediaTypeVideo);
    expect(videoAsset.descriptorTraits).to.contain(kPTNDescriptorTraitVideoKey);

    PHAsset *imageAsset = OCMPartialMock([[PHAsset alloc] init]);
    OCMStub(imageAsset.mediaType).andReturn(PHAssetMediaTypeImage);
    expect(imageAsset.descriptorTraits).to.equal([NSSet set]);

    PHAsset *asset = OCMPartialMock([[PHAsset alloc] init]);
    OCMStub(asset.mediaType).andReturn(PHAssetMediaTypeUnknown);
    expect(asset.descriptorTraits).to.equal([NSSet set]);
  });

  it(@"should reveal raw traits when the underlying asset is raw", ^{
    PHAsset *rawAsset = OCMPartialMock([[PHAsset alloc] init]);
    OCMStub([rawAsset uniformTypeIdentifier]).andReturn(@"com.adobe.raw-image");
    expect(rawAsset.descriptorTraits).to.contain(kPTNDescriptorTraitRawKey);

    PHAsset *jpegAsset = OCMPartialMock([[PHAsset alloc] init]);
    OCMStub([jpegAsset uniformTypeIdentifier]).andReturn(@"public.image");
    expect(jpegAsset.descriptorTraits).to.equal([NSSet set]);

    PHAsset *asset = OCMPartialMock([[PHAsset alloc] init]);
    expect(asset.descriptorTraits).to.equal([NSSet set]);
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
