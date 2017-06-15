// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "NSURL+MediaLibrary.h"

#import <LTKit/NSURL+Query.h>
#import <MediaPlayer/MediaPlayer.h>

SpecBegin(NSURL_MediaLibrary)

__block MPMediaItem *mediaLibraryItemMock;
__block MPMediaItemCollection *mediaLibraryCollectionMock;
__block NSURL *url;

beforeEach(^{
  mediaLibraryItemMock = OCMClassMock([MPMediaItem class]);
  mediaLibraryCollectionMock = OCMClassMock([MPMediaItemCollection class]);
});

it(@"should create media library asset URL with media item", ^{
  OCMStub([mediaLibraryItemMock persistentID]).andReturn(123);
  url = [NSURL ptn_mediaLibraryAssetURLWithItem:mediaLibraryItemMock];
  expect(url.scheme).to.equal(NSURL.ptn_mediaLibraryScheme);
  expect(url.host).to.equal(@"asset");
  expect(url.path).to.equal(@"/123");
  expect(url.ptn_mediaLibraryURLType).to.equal(PTNMediaLibraryURLTypeAsset);
  expect(url.ptn_mediaLibraryQueryType).to.beNil();
  expect(url.ptn_mediaLibraryPersistentID).to.equal(@123);
});

it(@"should create media library asset URL with media items collection", ^{
  OCMStub([mediaLibraryCollectionMock persistentID]).andReturn(321);
  url = [NSURL ptn_mediaLibraryAlbumURLWithCollection:mediaLibraryCollectionMock];
  expect(url.scheme).to.equal(NSURL.ptn_mediaLibraryScheme);
  expect(url.host).to.equal(@"album");
  expect(url.path).to.equal(@"/321");
  expect(url.ptn_mediaLibraryURLType).to.equal(PTNMediaLibraryURLTypeAlbum);
  expect(url.ptn_mediaLibraryQueryType).to.beNil();
  expect(url.ptn_mediaLibraryPersistentID).to.equal(@321);
});

it(@"should create query url with type", ^{
  [PTNMediaLibraryQueryType enumerateEnumUsingBlock:^(PTNMediaLibraryQueryType *value) {
    url = [NSURL ptn_mediaLibraryQueryURLWithType:value];
    expect(url.host).to.equal(@"query");
    expect(url.lt_queryDictionary[@"type"]).to.equal(value.name);
    expect(url.ptn_mediaLibraryURLType).to.equal(PTNMediaLibraryURLTypeQuery);
    expect(url.ptn_mediaLibraryQueryType).to.equal(value);
    expect(url.ptn_mediaLibraryPersistentID).to.beNil();
  }];
});

it(@"should create albums query URL", ^{
  expect([NSURL ptn_mediaLibraryAlbumsQueryURL])
      .to.equal([NSURL ptn_mediaLibraryQueryURLWithType:$(PTNMediaLibraryQueryTypeAlbums)]);
});

it(@"should create artist query URL", ^{
  expect([NSURL ptn_mediaLibraryArtistsQueryURL])
      .to.equal([NSURL ptn_mediaLibraryQueryURLWithType:$(PTNMediaLibraryQueryTypeArtists)]);
});

it(@"should create song query URL", ^{
  expect([NSURL ptn_mediaLibrarySongsQueryURL])
      .to.equal([NSURL ptn_mediaLibraryQueryURLWithType:$(PTNMediaLibraryQueryTypeSongs)]);
});

it(@"should return valid pesistent id", ^{
  MPMediaEntityPersistentID persistentID = 0xFEDCBA9876543210;
  OCMStub([mediaLibraryCollectionMock persistentID]).andReturn(persistentID);
  url = [NSURL ptn_mediaLibraryAlbumURLWithCollection:mediaLibraryCollectionMock];
  expect(url.ptn_mediaLibraryPersistentID).to.equal(@(persistentID));
});

it(@"should return nil when pesistent id is not valid", ^{
  auto components = [[NSURLComponents alloc] init];
  components.scheme = [NSURL ptn_mediaLibraryScheme];
  components.host = @"album";
  components.path = [NSString stringWithFormat:@"/%llu1", ULLONG_MAX];
  expect(components.URL.ptn_mediaLibraryPersistentID).to.beNil();

  components.path = @"foo";
  expect(components.URL.ptn_mediaLibraryPersistentID).to.beNil();
});

SpecEnd
