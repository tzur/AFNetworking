// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxFileDescriptor.h"

#import "PTNDropboxEntry.h"
#import "PTNDropboxTestUtils.h"
#import "NSURL+Dropbox.h"

SpecBegin(PTNDropboxFileDescriptor)

it(@"should return correct identifier", ^{
  NSDate *lastModified = [[NSDate alloc] init];
  DBMetadata *metadata =
      PTNDropboxCreateFileMetadataWithModificationDate(@"foo/bar.jpg", @"bar", lastModified);
  PTNDropboxFileDescriptor *asset = [[PTNDropboxFileDescriptor alloc] initWithMetadata:metadata];
  PTNDropboxEntry *entry = [PTNDropboxEntry entryWithPath:@"foo/bar.jpg" andRevision:@"bar"];

  expect(asset.ptn_identifier).to.equal([NSURL ptn_dropboxAssetURLWithEntry:entry]);
  expect(asset.localizedTitle).to.equal(@"bar.jpg");
  expect(asset.modificationDate).to.equal(lastModified);
});

it(@"should return correct identifier with latest revision", ^{
  NSDate *lastModified = [[NSDate alloc] init];
  DBMetadata *metadata =
      PTNDropboxCreateFileMetadataWithModificationDate(@"foo/bar.jpg", @"bar", lastModified);
  PTNDropboxFileDescriptor *asset = [[PTNDropboxFileDescriptor alloc] initWithMetadata:metadata
                                                                        latestRevision:YES];
  PTNDropboxEntry *entry = [PTNDropboxEntry entryWithPath:@"foo/bar.jpg" andRevision:nil];

  expect(asset.ptn_identifier).to.equal([NSURL ptn_dropboxAssetURLWithEntry:entry]);
  expect(asset.localizedTitle).to.equal(@"bar.jpg");
  expect(asset.modificationDate).to.equal(lastModified);
});

context(@"equality", ^{
  __block PTNDropboxFileDescriptor *firstFile;
  __block PTNDropboxFileDescriptor *secondFile;

  context(@"revision", ^{
    beforeEach(^{
      NSDate *lastModified = [[NSDate alloc] init];
      DBMetadata *metadata =
          PTNDropboxCreateFileMetadataWithModificationDate(@"foo/bar.jpg", @"bar", lastModified);

      firstFile = [[PTNDropboxFileDescriptor alloc] initWithMetadata:metadata];
      secondFile = [[PTNDropboxFileDescriptor alloc] initWithMetadata:metadata];
    });

    it(@"should handle isEqual correctly", ^{
      expect(firstFile).to.equal(secondFile);
      expect(secondFile).to.equal(firstFile);
    });

    it(@"should create proper hash", ^{
      expect(firstFile.hash).to.equal(secondFile.hash);
    });
  });
});

SpecEnd
