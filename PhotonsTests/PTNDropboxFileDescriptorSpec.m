// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxFileDescriptor.h"

#import "PTNDropboxEntry.h"
#import "PTNDropboxTestUtils.h"
#import "NSURL+Dropbox.h"

SpecBegin(PTNDropboxFileDescriptor)

static NSString * const kPath = @"foo/bar.jpg";
static NSString * const kRevision = @"bar";

__block PTNDropboxFileDescriptor *asset;
__block DBMetadata *metadata;

beforeEach(^{
  metadata = PTNDropboxCreateFileMetadata(kPath, kRevision);
  asset = [[PTNDropboxFileDescriptor alloc] initWithMetadata:metadata];
});

it(@"should return correct identifier", ^{
  PTNDropboxEntry *entry = [PTNDropboxEntry entryWithPath:kPath andRevision:kRevision];

  expect(asset.ptn_identifier).to.equal([NSURL ptn_dropboxAssetURLWithEntry:entry]);
});

it(@"should use last path component for localized title", ^{
  expect(asset.localizedTitle).to.equal(@"bar.jpg");
});

context(@"equality", ^{
  __block PTNDropboxFileDescriptor *firstDirectory;
  __block PTNDropboxFileDescriptor *secondDirectory;

  context(@"revision", ^{
    beforeEach(^{
      firstDirectory = [[PTNDropboxFileDescriptor alloc] initWithMetadata:metadata];
      secondDirectory = [[PTNDropboxFileDescriptor alloc] initWithMetadata:metadata];
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
