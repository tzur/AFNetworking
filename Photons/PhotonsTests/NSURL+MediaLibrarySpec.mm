// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "NSURL+MediaLibrary.h"

#import <LTKit/NSURL+Query.h>
#import <MediaPlayer/MediaPlayer.h>

SpecBegin(NSURL_MediaLibrary)
__block MPMediaItem *mediaLibraryItemMock;
__block NSURL *url;

beforeEach(^{
  mediaLibraryItemMock = OCMClassMock([MPMediaItem class]);
  OCMStub(mediaLibraryItemMock.persistentID).andReturn(123ULL);
  OCMStub(mediaLibraryItemMock.albumPersistentID).andReturn(345ULL);
});

it(@"should create asset URL with media item", ^{
  url = [NSURL ptn_mediaLibraryAssetWithItem:mediaLibraryItemMock];
  auto urlString = [NSString stringWithFormat:@"%@://asset?%@=123&"
                    "fetch=PTNMediaLibraryFetchTypeItems", [NSURL ptn_mediaLibraryScheme],
                    MPMediaItemPropertyPersistentID];
  expect(url).to.equal([NSURL URLWithString:urlString]);
  expect(url.ptn_mediaLibraryURLType).to.equal(PTNMediaLibraryURLTypeAsset);
  expect(url.ptn_mediaLibraryFetch).to.equal($(PTNMediaLibraryFetchTypeItems));
  expect(url.ptn_mediaLibraryGrouping).to.beNil();
});

it(@"should create music album songs URL with item", ^{
  url = [NSURL ptn_mediaLibraryAlbumMusicAlbumSongsWithItem:mediaLibraryItemMock];
  auto urlString = [NSString stringWithFormat:@"%@://album?%@=345&"
                    "fetch=PTNMediaLibraryFetchTypeItems", [NSURL ptn_mediaLibraryScheme],
                    MPMediaItemPropertyAlbumPersistentID];
  expect(url).to.equal([NSURL URLWithString:urlString]);
  expect(url.ptn_mediaLibraryURLType).to.equal(PTNMediaLibraryURLTypeAlbum);
  expect(url.ptn_mediaLibraryFetch).to.equal($(PTNMediaLibraryFetchTypeItems));
  expect(url.ptn_mediaLibraryGrouping).to.beNil();
});

it(@"should create artist's music album URL with item", ^{
  url = [NSURL ptn_mediaLibraryAlbumArtistMusicAlbumsWithItem:mediaLibraryItemMock];
  auto urlString = [NSString stringWithFormat:@"%@://album?%@=345&"
                    "fetch=PTNMediaLibraryFetchTypeCollections&grouping=MPMediaGroupingAlbum",
                    [NSURL ptn_mediaLibraryScheme], MPMediaItemPropertyAlbumPersistentID];
  expect(url).to.equal([NSURL URLWithString:urlString]);
  expect(url.ptn_mediaLibraryURLType).to.equal(PTNMediaLibraryURLTypeAlbum);
  expect(url.ptn_mediaLibraryFetch).to.equal($(PTNMediaLibraryFetchTypeCollections));
  expect(url.ptn_mediaLibraryGrouping).to.equal(@(MPMediaGroupingAlbum));
});

it(@"should create artist's songs URL with item", ^{
  url = [NSURL ptn_mediaLibraryAlbumArtistSongsWithItem:mediaLibraryItemMock];
  auto urlString = [NSString stringWithFormat:@"%@://album?%@=345&"
                    "fetch=PTNMediaLibraryFetchTypeItems", [NSURL ptn_mediaLibraryScheme],
                    MPMediaItemPropertyAlbumPersistentID];
  expect(url).to.equal([NSURL URLWithString:urlString]);
  expect(url.ptn_mediaLibraryURLType).to.equal(PTNMediaLibraryURLTypeAlbum);
  expect(url.ptn_mediaLibraryFetch).to.equal($(PTNMediaLibraryFetchTypeItems));
  expect(url.ptn_mediaLibraryGrouping).to.beNil();
});

it(@"should create all music albums songs URL", ^{
  auto url = [NSURL ptn_mediaLibraryAlbumSongsByMusicAlbum];
  auto urlString = [NSString stringWithFormat:@"%@://album?%@=1&"
                    "fetch=PTNMediaLibraryFetchTypeCollections&grouping=MPMediaGroupingAlbum",
                    [NSURL ptn_mediaLibraryScheme], MPMediaItemPropertyMediaType];
  expect(url).to.equal([NSURL URLWithString:urlString]);
  expect(url.ptn_mediaLibraryURLType).to.equal(PTNMediaLibraryURLTypeAlbum);
  expect(url.ptn_mediaLibraryFetch).to.equal($(PTNMediaLibraryFetchTypeCollections));
  expect(url.ptn_mediaLibraryGrouping).to.equal(@(MPMediaGroupingAlbum));
});

it(@"should create all artist songs URL", ^{
  auto url = [NSURL ptn_mediaLibraryAlbumSongsByAritst];
  auto urlString = [NSString stringWithFormat:@"%@://album?%@=1&"
                    "fetch=PTNMediaLibraryFetchTypeCollections&grouping=MPMediaGroupingArtist",
                    [NSURL ptn_mediaLibraryScheme], MPMediaItemPropertyMediaType];
  expect(url).to.equal([NSURL URLWithString:urlString]);
  expect(url.ptn_mediaLibraryURLType).to.equal(PTNMediaLibraryURLTypeAlbum);
  expect(url.ptn_mediaLibraryFetch).to.equal($(PTNMediaLibraryFetchTypeCollections));
  expect(url.ptn_mediaLibraryGrouping).to.equal(@(MPMediaGroupingArtist));
});

it(@"should create all songs URL", ^{
  auto url = [NSURL ptn_mediaLibraryAlbumSongs];
  auto urlString = [NSString stringWithFormat:@"%@://album?%@=1&"
                    "fetch=PTNMediaLibraryFetchTypeCollections&grouping=MPMediaGroupingTitle",
                    [NSURL ptn_mediaLibraryScheme], MPMediaItemPropertyMediaType];
  expect(url).to.equal([NSURL URLWithString:urlString]);
  expect(url.ptn_mediaLibraryURLType).to.equal(PTNMediaLibraryURLTypeAlbum);
  expect(url.ptn_mediaLibraryFetch).to.equal($(PTNMediaLibraryFetchTypeCollections));
  expect(url.ptn_mediaLibraryGrouping).to.equal(@(MPMediaGroupingTitle));
});

SpecEnd
