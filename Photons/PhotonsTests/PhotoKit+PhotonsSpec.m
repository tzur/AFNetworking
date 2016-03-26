// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "Photokit+Photons.h"

#import "PTNDescriptor.h"

SpecBegin(PhotoKit_Photons)

context(@"asset descriptor", ^{
  it(@"should have no localized title", ^{
    PHAsset *asset = OCMPartialMock([[PHAsset alloc] init]);

    expect(asset.localizedTitle).to.beNil();
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
});

SpecEnd
