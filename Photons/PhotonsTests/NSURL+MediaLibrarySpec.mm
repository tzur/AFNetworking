// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "NSURL+MediaLibrary.h"

#import <LTKit/NSArray+NSSet.h>
#import <LTKit/NSURL+Query.h>
#import <MediaPlayer/MediaPlayer.h>

#import "PTNMediaQueryProvider.h"

_Nullable id<PTNMediaQuery> PTNQuery(id<PTNMediaQueryProvider> provider, NSString *type,
                                     NSString *queryString) {
  auto urlString = [NSString stringWithFormat:@"%@://%@?%@", [NSURL ptn_mediaLibraryScheme],
                    type, queryString];
  auto url = [NSURL URLWithString:urlString];
  return [url ptn_mediaLibraryQueryWithProvider:provider];
}

_Nullable id<PTNMediaQuery> PTNAssetQuery(id<PTNMediaQueryProvider> provider,
                                          NSString *queryString) {
  return PTNQuery(provider, @"asset", queryString);
}

_Nullable id<PTNMediaQuery> PTNAlbumQuery(id<PTNMediaQueryProvider> provider,
                                          NSString *queryString) {
  return PTNQuery(provider, @"album", queryString);
}

SpecBegin(NSURL_MediaLibrary)
__block MPMediaItem *mediaLibraryItemMock;
__block NSURL *url;
__block id<PTNMediaQueryProvider> provider;

beforeEach(^{
  mediaLibraryItemMock = OCMClassMock([MPMediaItem class]);
  OCMStub(mediaLibraryItemMock.albumPersistentID).andReturn(345ULL);
  OCMStub(mediaLibraryItemMock.albumTitle).andReturn(@"AlbumTitle");
  OCMStub(mediaLibraryItemMock.artist).andReturn(@"Artist");
  OCMStub(mediaLibraryItemMock.artistPersistentID).andReturn(678ULL);
  OCMStub(mediaLibraryItemMock.mediaType).andReturn(1UL);
  OCMStub(mediaLibraryItemMock.persistentID).andReturn(123ULL);
  OCMStub(mediaLibraryItemMock.title).andReturn(@"Title");

  provider = [[PTNMediaQueryProvider alloc] init];
});

it(@"should return values of predicates", ^{
  auto url = [[NSURL alloc] init];
  expect([url ptn_valuesForPredicate:@"foo"]).to.equal(@[]);
  expect([url ptn_valuesForPredicate:@"bar"]).to.equal(@[]);

  url = [NSURL URLWithString:@"a://b/c?foo=bar&baz=qux&baz=quux"];
  expect([url ptn_valuesForPredicate:@"foo"]).to.equal(@[@"bar"]);
  expect([url ptn_valuesForPredicate:@"baz"]).to.equal(@[@"qux", @"quux"]);

  expect([url ptn_valuesForPredicate:@"bar"]).to.equal(@[]);
  expect([url ptn_valuesForPredicate:@"qux"]).to.equal(@[]);
  expect([url ptn_valuesForPredicate:@"quux"]).to.equal(@[]);
  expect([url ptn_valuesForPredicate:@"foobar"]).to.equal(@[]);
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
  auto urlString = [NSString stringWithFormat:@"%@://album?%@=678&"
                    "fetch=PTNMediaLibraryFetchTypeCollections&grouping=MPMediaGroupingAlbum",
                    [NSURL ptn_mediaLibraryScheme], MPMediaItemPropertyArtistPersistentID];
  expect(url).to.equal([NSURL URLWithString:urlString]);
  expect(url.ptn_mediaLibraryURLType).to.equal(PTNMediaLibraryURLTypeAlbum);
  expect(url.ptn_mediaLibraryFetch).to.equal($(PTNMediaLibraryFetchTypeCollections));
  expect(url.ptn_mediaLibraryGrouping).to.equal(@(MPMediaGroupingAlbum));
});

it(@"should create artist's songs URL with item", ^{
  url = [NSURL ptn_mediaLibraryAlbumArtistSongsWithItem:mediaLibraryItemMock];
  auto urlString = [NSString stringWithFormat:@"%@://album?%@=678&"
                    "fetch=PTNMediaLibraryFetchTypeItems", [NSURL ptn_mediaLibraryScheme],
                    MPMediaItemPropertyArtistPersistentID];
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

it(@"should return nil query for malformed asset url", ^{
  expect(PTNAssetQuery(provider, @"fetch=PTNMediaLibraryFetchTypeItems")).to.beNil();

  expect(PTNAssetQuery(provider, [NSString stringWithFormat:
      @"%@=1&fetch=PTNMediaLibraryFetchTypeCollections", MPMediaItemPropertyMediaType])).to.beNil();

  expect(PTNAssetQuery(provider, [NSString stringWithFormat:
      @"%@=1&fetch=f", MPMediaItemPropertyMediaType])).to.beNil();

  expect(PTNAssetQuery(provider, [NSString stringWithFormat:
      @"%@=1", MPMediaItemPropertyMediaType])).to.beNil();

  expect(PTNAssetQuery(provider, [NSString stringWithFormat:
      @"%@=1&fetch=PTNMediaLibraryFetchTypeItems&fetch=PTNMediaLibraryFetchTypeCollections",
      MPMediaItemPropertyMediaType])).to.beNil();

  expect(PTNAssetQuery(provider, [NSString stringWithFormat:
      @"%@=1&fetch=PTNMediaLibraryFetchTypeItems&grouping=MPMediaGroupingTitle",
      MPMediaItemPropertyMediaType])).to.beNil();

  expect(PTNAssetQuery(provider, [NSString stringWithFormat:
    @"foo=1&fetch=PTNMediaLibraryItems"])).to.beNil();

  expect(PTNAssetQuery(provider, [NSString stringWithFormat:
    @"%@=1&foo=%@&fetch=PTNMediaLibraryFetchTypeItems", MPMediaItemPropertyMediaType,
    MPMediaItemPropertyMediaType])).to.beNil();

  expect(PTNAssetQuery(provider, [NSString stringWithFormat:
    @"%@=1&foo=2&fetch=PTNMediaLibraryFetchTypeItems", MPMediaItemPropertyMediaType])).to.beNil();

  expect(PTNAssetQuery(provider, [NSString stringWithFormat:
    @"%@=1&fetch=PTNMediaLibraryFetchTypeItems&foo=bar", MPMediaItemPropertyMediaType])).to.beNil();
});

it(@"should return nil query for malformed album url", ^{
  expect(PTNAlbumQuery(provider, [NSString stringWithFormat:@"%@=1",
    MPMediaItemPropertyMediaType])).to.beNil();

  expect(PTNAlbumQuery(provider, [NSString stringWithFormat:
    @"%@=1&fetch=PTNMediaLibraryFetchTypeItems&fetch=PTNMediaLibraryFetchTypeItems",
    MPMediaItemPropertyMediaType])).to.beNil();

  expect(PTNAlbumQuery(provider, [NSString stringWithFormat:
    @"%@=1&fetch=foo", MPMediaItemPropertyMediaType])).to.beNil();

  expect(PTNAlbumQuery(provider, [NSString stringWithFormat:
    @"%@=1&fetch=PTNMediaLibraryFetchTypeItems&foo=bar", MPMediaItemPropertyMediaType])).to.beNil();

  expect(PTNAlbumQuery(provider, [NSString stringWithFormat:
    @"foo=1&fetch=PTNMediaLibraryFetchTypeItems"])).to.beNil();

  expect(PTNAlbumQuery(provider, [NSString stringWithFormat:
    @"foo=%@&fetch=PTNMediaLibraryFetchTypeItems", MPMediaItemPropertyMediaType])) .to.beNil();

  expect(PTNAlbumQuery(provider, [NSString stringWithFormat:
    @"%@=1&fetch=PTNMediaLibraryFetchTypeItems&grouping=foo",
    MPMediaItemPropertyMediaType])).to.beNil();

  expect(PTNAlbumQuery(provider, [NSString stringWithFormat:
    @"%@=1&fetch=PTNMediaLibraryFetchTypeItems&grouping=MPMediaGroupingGenre&grouping=foo",
    MPMediaItemPropertyMediaType])).to.beNil();
});

it(@"should return a valid asset query", ^{
  auto query = PTNAssetQuery(provider, [NSString stringWithFormat:
    @"%@=1&%@=345&%@=AlbumTitle&%@=Artist&%@=678&%@=123&%@=Title&"
    "fetch=PTNMediaLibraryFetchTypeItems", MPMediaItemPropertyMediaType,
    MPMediaItemPropertyAlbumPersistentID, MPMediaItemPropertyAlbumTitle, MPMediaItemPropertyArtist,
    MPMediaItemPropertyArtistPersistentID, MPMediaItemPropertyPersistentID,
    MPMediaItemPropertyTitle]);

  auto expectedPredicates = [@[
      [MPMediaPropertyPredicate predicateWithValue:@(1UL) forProperty:MPMediaItemPropertyMediaType],
      [MPMediaPropertyPredicate predicateWithValue:@(345ULL)
                                       forProperty:MPMediaItemPropertyAlbumPersistentID],
      [MPMediaPropertyPredicate predicateWithValue:@"AlbumTitle"
                                       forProperty:MPMediaItemPropertyAlbumTitle],
      [MPMediaPropertyPredicate predicateWithValue:@"Artist" forProperty:MPMediaItemPropertyArtist],
      [MPMediaPropertyPredicate predicateWithValue:@(678ULL)
                                       forProperty:MPMediaItemPropertyArtistPersistentID],
      [MPMediaPropertyPredicate predicateWithValue:@(123ULL)
                                       forProperty:MPMediaItemPropertyPersistentID],
      [MPMediaPropertyPredicate predicateWithValue:@"Title" forProperty:MPMediaItemPropertyTitle]
  ] lt_set];

  auto actualPredicates = query.filterPredicates;

  expect(expectedPredicates).to.equal(actualPredicates);
});

it(@"should return a valid album query", ^{
  auto query = PTNAlbumQuery(provider, [NSString stringWithFormat:
      @"%@=1&fetch=PTNMediaLibraryFetchTypeCollections&grouping=MPMediaGroupingGenre",
      MPMediaItemPropertyMediaType]);
  auto expectedPredicates = [NSSet setWithObject:[MPMediaPropertyPredicate predicateWithValue:@(1UL)
                                                  forProperty:MPMediaItemPropertyMediaType]];
  auto actualPredicates = query.filterPredicates;

  expect(expectedPredicates).to.equal(actualPredicates);
  expect(query.groupingType).to.equal(MPMediaGroupingGenre);
});

it(@"should return nil query when pid is not valid", ^{
  auto hugeNumberString = [NSString stringWithFormat:@"%llu0",
                           std::numeric_limits<unsigned long long>::max()];
  auto query = PTNAlbumQuery(provider, [NSString stringWithFormat:
      @"%@=%@&fetch=PTNMediaLibraryFetchTypeItems", MPMediaItemPropertyPersistentID,
      hugeNumberString]);

  expect(query).to.beNil();
});

SpecEnd
