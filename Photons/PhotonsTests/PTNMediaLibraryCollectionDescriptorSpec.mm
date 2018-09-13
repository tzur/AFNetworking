// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "PTNMediaLibraryCollectionDescriptor.h"

#import <MediaPlayer/MediaPlayer.h>

#import "NSURL+MediaLibrary.h"

SpecBegin(PTNMediaLibraryCollectionDescriptor)

__block MPMediaItemCollection *collection;
__block PTNMediaLibraryCollectionDescriptor *descriptor;
__block NSURL *url;

beforeEach(^{
  MPMediaItem *item = OCMClassMock([MPMediaItem class]);
  OCMStub(item.albumTitle).andReturn(@"albumTitle");
  collection = [[MPMediaItemCollection alloc] initWithItems:@[item]];
  url = [NSURL ptn_mediaLibraryAlbumSongs];
  descriptor = [[PTNMediaLibraryCollectionDescriptor alloc] initWithCollection:collection url:url];
});

it(@"should return assets count", ^{
  expect(descriptor.assetCount).to.equal(1);
});

it(@"should return album descriptor capabilities", ^{
  expect(descriptor.albumDescriptorCapabilities).to.equal(PTNAlbumDescriptorCapabilityNone);
});

it(@"should return photons identifier", ^{
  expect(descriptor.ptn_identifier).to.equal(url);
});

it(@"should return artist as localized title when initialized with artist url", ^{
  MPMediaItem *item = OCMClassMock([MPMediaItem class]);
  OCMStub(item.artist).andReturn(@"artist");
  OCMStub(item.artistPersistentID).andReturn(123ULL);

  auto collection = [[MPMediaItemCollection alloc] initWithItems:@[item]];
  auto urlString = [NSString stringWithFormat:@"%@://album?%@=123&fetch=PTNMediaLibraryFetchItems",
                    [NSURL ptn_mediaLibraryScheme], MPMediaItemPropertyArtistPersistentID];
  auto url = [NSURL URLWithString:urlString];
  auto descriptor = [[PTNMediaLibraryCollectionDescriptor alloc] initWithCollection:collection
                                                                                url:url];

  expect(descriptor.localizedTitle).to.equal(@"artist");
});

it(@"should return album title as localized title when initialized with album url", ^{
  expect(descriptor.localizedTitle).to.equal(@"albumTitle");
});

it(@"should return descriptor capabilities", ^{
  expect(descriptor.descriptorCapabilities).to.equal(PTNDescriptorCapabilityNone);
});

it(@"should return descriptor traits", ^{
  expect(descriptor.descriptorTraits).to.equal([NSSet set]);
});

it(@"should return collection it was initialized with", ^{
  expect(descriptor.collection).to.equal(collection);
});

it(@"should return url it was initialized with", ^{
  expect(descriptor.url).to.equal(url);
});

SpecEnd
