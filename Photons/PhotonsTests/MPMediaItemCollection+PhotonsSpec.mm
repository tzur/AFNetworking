// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "MPMediaItemCollection+Photons.h"

#import "NSURL+MediaLibrary.h"

SpecBegin(MPMediaItemCollection_Photons)

__block MPMediaItemCollection *collection;
__block MPMediaItem *item;

beforeEach(^{
  item = OCMClassMock([MPMediaItem class]);
  MPMediaItem *item2 = OCMClassMock([MPMediaItem class]);
  collection = [MPMediaItemCollection collectionWithItems:@[item, item2]];
});

it(@"should return correct asset count", ^{
  expect(collection.assetCount).to.equal(2);
});

it(@"should return album descriptor capability none", ^{
  expect(collection.albumDescriptorCapabilities).to.equal(PTNAlbumDescriptorCapabilityNone);
});

it(@"should return Photons identifier url", ^{
  collection = OCMClassMock([MPMediaItemCollection class]);
  OCMStub(collection.persistentID).andReturn(123);
  auto url = [NSURL ptn_mediaLibraryAlbumURLWithCollection:collection];

  MPMediaItemCollection *collectionPartialMock =
      OCMPartialMock([MPMediaItemCollection collectionWithItems:@[item]]);
  OCMStub(collectionPartialMock.persistentID).andReturn(123);

  expect(collectionPartialMock.ptn_identifier).to.equal(url);
});

it(@"should return localized title", ^{
  OCMStub(item.albumTitle).andReturn(@"foo");
  collection = OCMPartialMock([MPMediaItemCollection collectionWithItems:@[item]]);
  OCMStub(collection.representativeItem).andReturn(item);

  expect(collection.localizedTitle).to.equal(@"foo");
});

it(@"should return descriptor capabilities none", ^{
  expect(collection.descriptorCapabilities).to.equal(PTNDescriptorCapabilityNone);
});

it(@"should return no descriptor traits", ^{
  expect(collection.descriptorTraits).notTo.beNil();
  expect(collection.descriptorTraits.count).to.equal(0);
});

SpecEnd
