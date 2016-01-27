// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxDirectoryDescriptor.h"

#import <DropboxSDK/DropboxSDK.h>

#import "PTNDropboxEntry.h"
#import "PTNDropboxTestUtils.h"
#import "NSURL+Dropbox.h"

SpecBegin(PTNDropboxDirectoryDescriptor)

static NSString * const kPath = @"foo/bar";
static NSString * const kRevision = @"bar";

__block PTNDropboxDirectoryDescriptor *asset;
__block DBMetadata *metadata;

beforeEach(^{
  metadata = PTNDropboxCreateDirectoryMetadata(kPath, kRevision);
  asset = [[PTNDropboxDirectoryDescriptor alloc] initWithMetadata:metadata];
});

it(@"should return correct identifier", ^{
  PTNDropboxEntry *entry = [PTNDropboxEntry entryWithPath:kPath andRevision:kRevision];

  expect(asset.ptn_identifier).to.equal([NSURL ptn_dropboxAlbumURLWithEntry:entry]);
});

it(@"should use last path component for localized title", ^{
  expect(asset.localizedTitle).to.equal(@"bar");
});

it(@"should return correct asset count if available", ^{
  NSArray *contents = @[
    PTNDropboxCreateFileMetadata(@"foo", nil),
    PTNDropboxCreateFileMetadata(@"bar", nil),
    PTNDropboxCreateDirectoryMetadata(@"baz", nil)
  ];
  OCMStub([metadata contents]).andReturn(contents);
  asset = [[PTNDropboxDirectoryDescriptor alloc] initWithMetadata:metadata];

  expect([asset assetCount]).to.equal(2);
});

it(@"should return default asset count if unavailable", ^{
  expect([asset assetCount]).to.equal(PTNNotFound);
});

context(@"equality", ^{
  __block PTNDropboxDirectoryDescriptor *firstDirectory;
  __block PTNDropboxDirectoryDescriptor *secondDirectory;

  context(@"revision", ^{
    beforeEach(^{
      firstDirectory = [[PTNDropboxDirectoryDescriptor alloc] initWithMetadata:metadata];
      secondDirectory = [[PTNDropboxDirectoryDescriptor alloc] initWithMetadata:metadata];
    });

    it(@"should handle isEqual correctly", ^{
      expect(firstDirectory).to.equal(secondDirectory);
      expect(secondDirectory).to.equal(firstDirectory);
    });

    it(@"should create proper hash", ^{
      expect(firstDirectory.hash).to.equal(secondDirectory.hash);
    });
  });
});

SpecEnd
