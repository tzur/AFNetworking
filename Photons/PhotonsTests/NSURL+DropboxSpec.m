// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "NSURL+Dropbox.h"

#import "PTNDropboxEntry.h"
#import "PTNNSURLTestUtils.h"

static NSString * const kPath = @"/foo/bar";
static NSString * const kRevision = @"baz";

SpecBegin(NSURL_Dropbox)

it(@"should return valid asset URL", ^{
  PTNDropboxEntry *asset = [PTNDropboxEntry entryWithPath:kPath andRevision:kRevision];

  NSURL *url = [NSURL ptn_dropboxAssetURLWithEntry:asset];
  expect(url.ptn_dropboxURLType).to.equal(PTNDropboxURLTypeAsset);
  expect(url.ptn_dropboxAssetEntry).to.equal(asset);
  expect(url.ptn_dropboxAlbumEntry).to.beNil();
});

it(@"should return valid album URL", ^{
  PTNDropboxEntry *album = [PTNDropboxEntry entryWithPath:kPath andRevision:kRevision];

  NSURL *url = [NSURL ptn_dropboxAlbumURLWithEntry:album];
  expect(url.ptn_dropboxURLType).to.equal(PTNDropboxURLTypeAlbum);
  expect(url.ptn_dropboxAlbumEntry).to.equal(album);
  expect(url.ptn_dropboxAssetEntry).to.beNil();
});

it(@"should return nil entry for invalid url", ^{
  NSURL *url = [NSURL URLWithString:@"http://www.foo.com"];
  expect(url.ptn_dropboxAssetEntry).to.beNil();
  expect(url.ptn_dropboxAlbumEntry).to.beNil();
  expect(url.ptn_dropboxURLType).to.equal(PTNDropboxURLTypeInvalid);
});

it(@"should return nil asset for url with no path query", ^{
  NSURL *url = PTNCreateURL([NSURL ptn_dropboxScheme], @"asset", @[]);
  expect(url.ptn_dropboxAssetEntry).to.beNil();
});

it(@"should return nil album for url with no path query", ^{
  NSURL *url = PTNCreateURL([NSURL ptn_dropboxScheme], @"album", @[]);
  expect(url.ptn_dropboxAlbumEntry).to.beNil();
});

SpecEnd
