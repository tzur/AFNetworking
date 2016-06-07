// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSURL+FileSystem.h"

#import <LTKit/LTPath.h>

#import "PTNNSURLTestUtils.h"

SpecBegin(NSURL_FileSystem)

static NSString * const kPath = @"/foo/baz";

it(@"should return valid asset url", ^{
  LTPath *path = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryTemp andRelativePath:kPath];
  NSURL *url = [NSURL ptn_fileSystemAssetURLWithPath:path];

  expect(url.ptn_fileSystemAssetPath).to.equal(path);
  expect(url.ptn_fileSystemURLType).to.equal(PTNFileSystemURLTypeAsset);
  expect(url.ptn_fileSystemAlbumPath).to.beNil();
});

it(@"should return valid album url", ^{
  LTPath *path = [LTPath pathWithBaseDirectory:LTPathBaseDirectoryTemp andRelativePath:kPath];
  NSURL *url = [NSURL ptn_fileSystemAlbumURLWithPath:path];

  expect(url.ptn_fileSystemAlbumPath).to.equal(path);
  expect(url.ptn_fileSystemURLType).to.equal(PTNFileSystemURLTypeAlbum);
  expect(url.ptn_fileSystemAssetPath).to.beNil();
});

it(@"should return nil path for invalid url", ^{
  NSURL *url = [NSURL URLWithString:@"http://www.foo.com"];
  expect(url.ptn_fileSystemAssetPath).to.beNil();
  expect(url.ptn_fileSystemAlbumPath).to.beNil();
  expect(url.ptn_fileSystemURLType).to.equal(PTNFileSystemURLTypeInvalid);
});

it(@"should return nil path for asset url with invalid base path name", ^{
  NSURL *url = PTNCreateURL([NSURL ptn_fileSystemScheme], @"asset", @[
    [[NSURLQueryItem alloc] initWithName:@"base" value:@"bar"],
    [[NSURLQueryItem alloc] initWithName:@"relative" value:kPath],
  ]);
  expect(url.ptn_fileSystemAssetPath).to.beNil();
});

it(@"should return nil path for album url with invalid base path name", ^{
  NSURL *url = PTNCreateURL([NSURL ptn_fileSystemScheme], @"album", @[
    [[NSURLQueryItem alloc] initWithName:@"base" value:@"bar"],
    [[NSURLQueryItem alloc] initWithName:@"relative" value:kPath],
  ]);
  expect(url.ptn_fileSystemAlbumPath).to.beNil();
});

it(@"should return nil asset for url with no base query", ^{
  NSURL *url = PTNCreateURL([NSURL ptn_fileSystemScheme], @"asset", @[
    [[NSURLQueryItem alloc] initWithName:@"relative" value:kPath],
  ]);
  expect(url.ptn_fileSystemAssetPath).to.beNil();
});

it(@"should return nil album for url with no base query", ^{
  NSURL *url = PTNCreateURL([NSURL ptn_fileSystemScheme], @"album", @[
    [[NSURLQueryItem alloc] initWithName:@"relative" value:kPath],
  ]);
  expect(url.ptn_fileSystemAlbumPath).to.beNil();
});

it(@"should return nil asset for url with no path query", ^{
  NSURL *url = PTNCreateURL([NSURL ptn_fileSystemScheme], @"asset", @[
    [[NSURLQueryItem alloc] initWithName:@"base" value:@"none"],
  ]);
  expect(url.ptn_fileSystemAssetPath).to.beNil();
});

it(@"should return nil album for url with no path query", ^{
  NSURL *url = PTNCreateURL([NSURL ptn_fileSystemScheme], @"album", @[
    [[NSURLQueryItem alloc] initWithName:@"base" value:@"none"],
  ]);
  expect(url.ptn_fileSystemAlbumPath).to.beNil();
});

SpecEnd
